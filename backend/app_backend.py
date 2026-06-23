# This Python file uses the following encoding: utf-8
"""
Backend principal exposé à QML via setContextProperty("backend", backend).

Responsabilités :
  - Authentification administrateur
  - Chargement et rafraîchissement des listes (pompes, projets)
  - Slots métier (calcul EC, sauvegarde projet)
  - Opérations CRUD admin sur la BDD
"""

from __future__ import annotations

import hashlib
import json
import tomllib
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot

from database.db import DatabaseManager
from core.pump import Pump
from core.graph import Graph
from reports.print_report import PrintReport


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def _load_config() -> dict:
    config_path = Path(__file__).resolve().parent.parent / "config.toml"
    with open(config_path, "rb") as f:
        return tomllib.load(f)


# ---------------------------------------------------------------------------
# Backend
# ---------------------------------------------------------------------------

class Backend(QObject):

    # --- Signaux ---
    adminStatusChanged  = Signal(bool)
    adminErrorChanged   = Signal(str)
    tableListChanged    = Signal()
    tableContentChanged = Signal()
    titleChanged        = Signal(str)
    pumpsChanged        = Signal()
    projectsChanged     = Signal()

    def __init__(self):
        super().__init__()
        self._config        = _load_config()
        self._is_admin      = False
        self._admin_error   = ""
        self._table_list:   list[str]  = []
        self._table_cols:   list[str]  = []
        self._table_rows:   list       = []
        self._title         = "Bienvenue sur MyHydraulicApp !"
        self._pumps:        dict       = {"": {"flowrate": 0, "head": 0, "pumpEff": 0, "motorEff": 0}}
        self._projects:     dict       = {"": ""}

        self._db = DatabaseManager()

        self._load_pumps()
        self._load_projects()

    # =======================================================================
    # Propriétés QML
    # =======================================================================

    @Property(bool, notify=adminStatusChanged)
    def isAdmin(self) -> bool:
        return self._is_admin

    @Property(str, notify=adminErrorChanged)
    def adminError(self) -> str:
        return self._admin_error

    @Property("QVariant", notify=tableListChanged)
    def tableList(self) -> list[str]:
        return self._table_list

    @Property("QVariant", notify=tableContentChanged)
    def tableCols(self) -> list[str]:
        return self._table_cols

    @Property("QVariant", notify=tableContentChanged)
    def tableRows(self) -> list:
        return self._table_rows

    @Property(str, notify=titleChanged)
    def title(self) -> str:
        return self._title

    @title.setter
    def title(self, value: str):
        if self._title != value:
            self._title = value
            self.titleChanged.emit(value)

    @Property("QVariant", notify=pumpsChanged)
    def pumps(self) -> dict:
        return self._pumps

    @Property("QVariant", notify=projectsChanged)
    def projects(self) -> dict:
        return self._projects

    # =======================================================================
    # Authentification Admin
    # =======================================================================

    @Slot(str, str, result=bool)
    def adminLogin(self, login: str, password: str) -> bool:
        cfg = self._config["admin"]
        if login == cfg["login"] and _sha256(password) == cfg["password_sha"]:
            self._is_admin    = True
            self._admin_error = ""
            self.adminStatusChanged.emit(True)
            self._refresh_table_list()
            return True
        self._admin_error = "Login ou mot de passe incorrect."
        self.adminErrorChanged.emit(self._admin_error)
        return False

    @Slot()
    def adminLogout(self):
        self._is_admin    = False
        self._table_list  = []
        self._table_cols  = []
        self._table_rows  = []
        self.adminStatusChanged.emit(False)
        self.tableListChanged.emit()
        self.tableContentChanged.emit()

    # =======================================================================
    # Gestion admin des tables
    # =======================================================================

    def _refresh_table_list(self):
        self._table_list = self._db.get_table_names()
        self.tableListChanged.emit()

    @Slot(str)
    def loadTable(self, table_name: str):
        """Charge le contenu d'une table et notifie QML."""
        self._table_cols = self._db.get_columns(table_name)
        rows = self._db.get_all_rows(table_name)
        self._table_rows = [
            [str(row.get(col, "")) for col in self._table_cols]
            for row in rows
        ]
        self.tableContentChanged.emit()

    @Slot(str, int, str, str, result=bool)
    def adminUpdateCell(self, table_name: str, row_id: int, column: str, value: str) -> bool:
        """Met à jour une cellule identifiée par (table, id, colonne)."""
        return self._db.update_row(table_name, row_id, {column: value})

    @Slot(str, int, result=bool)
    def adminDeleteRow(self, table_name: str, row_id: int) -> bool:
        """Supprime une ligne et recharge la table."""
        ok = self._db.delete_row(table_name, row_id)
        if ok:
            self.loadTable(table_name)
        return ok

    # =======================================================================
    # Données métier — Pompes
    # =======================================================================

    def _load_pumps(self):
        self._pumps = {"": {"flowrate": 0, "head": 0, "pumpEff": 0, "motorEff": 0}}
        for row in self._db.get_all_rows("T_PUMPS"):
            key = f"{row.get('BRAND','')} - {row.get('NAME','')}"
            self._pumps[key] = {
                "id":       row.get("id"),
                "flowrate": row.get("NOMINAL_FLOW", 0),
                "head":     row.get("NOMINAL_HEAD", 0),
                "pumpEff":  row.get("EFF_PUMP", 0),
                "motorEff": row.get("EFF_MOTOR", 0),
            }
        self.pumpsChanged.emit()

    @Slot("QVariant", result=bool)
    def updatePumpList(self, _data) -> bool:
        """Recharge la liste des pompes depuis la BDD."""
        self._load_pumps()
        return True

    # =======================================================================
    # Données métier — Projets
    # =======================================================================

    def _load_projects(self):
        self._projects = {"": ""}
        for row in self._db.get_all_rows("T_PROJECTS"):
            key = f"{row.get('SALES_REP','')} - {row.get('NAME','')} - {row.get('CUSTOMER','')}"
            self._projects[key] = {
                "id":       row.get("id"),
                "name":     row.get("NAME", ""),
                "customer": row.get("CUSTOMER", ""),
                "salesRep": row.get("SALES_REP", ""),
                "pump1":    row.get("PUMP1", "{}"),
                "pump2":    row.get("PUMP2", "{}"),
                "nrjCost":  float(row.get("NRJ_COST") or 0),
                "co2Coef":  float(row.get("CO2_COEF") or 0),
            }
        self.projectsChanged.emit()

    # =======================================================================
    # Slots métier génériques
    # =======================================================================

    @Slot(str, "QVariant", result=bool)
    def addValue(self, table: str, data) -> bool:
        """Insère une ligne dans la table indiquée."""
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        self._db.insert_row(table, _data)
        return True

    # =======================================================================
    # Slot Energy Check — calcul + rapport
    # =======================================================================

    @Slot("QVariant", "QVariant", str, str, float, float)
    def getValues(self, pump1, pump2, project: str, customer: str,
                  energy_cost: float, co2: float) -> bool:
        """
        Calcule l'Energy Check, génère les graphiques et le rapport pptx.
        """
        current_year = datetime.now().year

        p1 = pump1.toVariant() if hasattr(pump1, "toVariant") else pump1
        p2 = pump2.toVariant() if hasattr(pump2, "toVariant") else pump2

        years1 = current_year - int(p1["year"])
        years2 = current_year - int(p2["year"])

        _pump1 = Pump(p1["pumpEff"], p1["motorEff"], 1, p1["flowrate"], p1["head"], years1)
        _pump2 = Pump(p2["pumpEff"], p2["motorEff"], 1, p2["flowrate"], p2["head"], years2)

        x      = list(range(0, 16))
        colors = ["blue", "red"]

        graph_power = Graph(_pump1, _pump2, "graphLinePower.png", "Puissance",
                            colors, "Années", x, "Puissance cumulée (*1000 kWh)")
        graph_power.prepareGraphPower(title1=p1["name"], title2=p2["name"],
                                      timeP1=p1["hours"], timeP2=p2["hours"])
        img_power = graph_power.line()

        graph_cost = Graph(_pump1, _pump2, "graphLineCost.png", "Coût Total",
                           colors, "Années", x, "Coût Total cumulé (k€)")
        graph_cost.prepareGraphCost(title1=p1["name"], title2=p2["name"],
                                    timeP1=p1["hours"], timeP2=p2["hours"],
                                    energyCost=energy_cost,
                                    extraCostP1=p1["cost"] / 1000,
                                    extraCostP2=p2["cost"] / 1000)
        img_cost = graph_cost.line()

        power1     = round(_pump1.current_power(), 2)
        power2     = round(_pump2.current_power(), 2)
        nrj_saving = int(power1 * p1["hours"] - power2 * p2["hours"])
        invest_tot = p2["cost"] - p1["cost"]
        cost_saving = int(nrj_saving * energy_cost)
        roi         = round(invest_tot / cost_saving, 2) if cost_saving else 0
        co2_saving  = int(nrj_saving * co2 / 1000)   # en tonnes

        data_report = {
            "title":       project,
            "customer":    customer,
            "eco_euros":   str(cost_saving),
            "roi":         str(roi),
            "eco_nrj":     str(nrj_saving),
            "eco_co2":     str(co2_saving),
            "invest":      str(invest_tot),
            "eco_10y":     "",
            "eco_15y":     "",
            "trees_qty":   str(int(co2_saving * 40)),
            "cars_qty":    str(int(co2_saving * 0.25)),
            "nrj_cost":    str(energy_cost),
            "total_invest":str(invest_tot),
            "effLoss":     str(graph_power.eff_loss),
            "pump1":       p1["name"],
            "pump2":       p2["name"],
            "power1":      str(power1),
            "power2":      str(power2),
            "eff1":        str(round(_pump1.current_eff(), 1)),
            "eff2":        str(round(_pump2.current_eff(), 1)),
            "q_h1":        f'{p1["flowrate"]} - {p1["head"]}',
            "q_h2":        f'{p2["flowrate"]} - {p2["head"]}',
            "time1":       str(int(p1["hours"])),
            "time2":       str(int(p2["hours"])),
            "img_power":   img_power,
            "img_cost":    img_cost,
        }

        PrintReport().print_pptx(data_report)
        return True
