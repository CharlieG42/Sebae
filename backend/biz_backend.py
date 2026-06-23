# This Python file uses the following encoding: utf-8
"""
Backend du module "Projet".
Expose à QML : CRUD sur Projets et Articles, et réutilise les tables
Clients / Contacts du module Contrats d'entretien.

Convention identique à maint_backend.py : les slots renvoient des
dicts/listes déjà aplatis, prêts pour QML.
"""

from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot

from database.db import DatabaseManager

T_PROJECTS = "T_BIZ_PROJECTS"
T_ARTICLES = "T_BIZ_ARTICLES"
T_CLIENTS  = "T_MAINT_CLIENTS"
T_CONTACTS = "T_MAINT_CONTACTS"

ARTICLE_TYPES = ["Produit", "Prestation interne", "Prestation externe", "Achat externe"]


class BizBackend(QObject):

    projectsChanged = Signal()
    articlesChanged  = Signal()

    def __init__(self):
        super().__init__()
        self._db = DatabaseManager()

    # =======================================================================
    # Helpers internes
    # =======================================================================

    @staticmethod
    def _client_label(client: dict | None) -> str:
        if not client:
            return ""
        c4c  = client.get("id_c4c") or ""
        name = client.get("name") or ""
        return f"{c4c} - {name}" if c4c else name

    @staticmethod
    def _contact_label(contact: dict | None) -> str:
        if not contact:
            return ""
        first = contact.get("first_name") or ""
        last  = contact.get("last_name") or ""
        return f"{first} {last}".strip()

    @staticmethod
    def _compute_article_fields(row: dict) -> dict:
        """Calcule PCTM, PCTR, GRPi à partir des champs stockés."""
        qty        = float(row.get("quantity") or 0)
        total_cost = float(row.get("total_cost") or 0)
        sale_price = float(row.get("sale_price") or 0)
        grp        = row.get("grp")

        pctm = (sale_price - total_cost) * qty
        pctr = (pctm / sale_price * 100) if sale_price else 0.0
        grpi = (sale_price * 100 / grp) if grp else 0.0

        row["pctm"] = round(pctm, 2)
        row["pctr"] = round(pctr, 2)
        row["grpi"] = round(grpi, 2)
        return row

    def _enrich_project(self, row: dict, clients_by_id: dict, contacts_by_id: dict) -> dict:
        client  = clients_by_id.get(row.get("client_id"))
        contact = contacts_by_id.get(row.get("contact_id"))
        row["client_label"] = self._client_label(client)
        row["contact_name"] = self._contact_label(contact)
        return row

    def _enrich_article(self, row: dict, projects_by_id: dict) -> dict:
        project = projects_by_id.get(row.get("project_id"))
        row["project_no"] = project["project_no"] if project else ""
        row["project_label"] = (
            f"{project['project_no']} - {project['name']}" if project else ""
        )
        return self._compute_article_fields(row)

    # =======================================================================
    # Options pour ComboBox (réutilise Clients / Contacts)
    # =======================================================================

    @Slot(result="QVariant")
    def getClientOptions(self) -> list[dict]:
        clients = self._db.get_all_rows(T_CLIENTS)
        return [{"id": c["id"], "label": self._client_label(c)} for c in clients]

    @Slot(int, result="QVariant")
    def getContactOptionsForClient(self, client_id: int) -> list[dict]:
        contacts = self._db.get_rows_by_column(T_CONTACTS, "client_id", client_id)
        return [{"id": c["id"], "label": self._contact_label(c)} for c in contacts]

    @Slot(result="QVariant")
    def getProjectOptions(self) -> list[dict]:
        """[{id, label}] — label au format '<N° projet> - <Nom>'."""
        projects = self._db.get_all_rows(T_PROJECTS)
        return [{"id": p["id"], "label": f"{p['project_no']} - {p['name']}"} for p in projects]

    @Slot(result="QVariant")
    def getArticleTypes(self) -> list[str]:
        return ARTICLE_TYPES

    # =======================================================================
    # Projets
    # =======================================================================

    @Slot(result="QVariant")
    def getProjects(self) -> list[dict]:
        clients  = {c["id"]: c for c in self._db.get_all_rows(T_CLIENTS)}
        contacts = {c["id"]: c for c in self._db.get_all_rows(T_CONTACTS)}
        rows = self._db.get_all_rows(T_PROJECTS)
        return [self._enrich_project(r, clients, contacts) for r in rows]

    @Slot(int, result="QVariant")
    def getProject(self, project_id: int):
        rows = self._db.get_rows_by_column(T_PROJECTS, "id", project_id)
        return rows[0] if rows else None

    @Slot("QVariant", result=int)
    def addProject(self, data) -> int:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        new_id = self._db.insert_row(T_PROJECTS, _data)
        self.projectsChanged.emit()
        return new_id or -1

    @Slot(int, "QVariant", result=bool)
    def updateProject(self, project_id: int, data) -> bool:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        ok = self._db.update_row(T_PROJECTS, project_id, _data)
        self.projectsChanged.emit()
        return ok

    @Slot(int, result=bool)
    def deleteProject(self, project_id: int) -> bool:
        # Détache les articles liés avant suppression (intégrité)
        for a in self._db.get_rows_by_column(T_ARTICLES, "project_id", project_id):
            self._db.update_row(T_ARTICLES, a["id"], {"project_id": None})
        ok = self._db.delete_row(T_PROJECTS, project_id)
        self.projectsChanged.emit()
        self.articlesChanged.emit()
        return ok

    @Slot(int, result="QVariant")
    def getArticlesForProject(self, project_id: int) -> list[dict]:
        rows = self._db.get_rows_by_column(T_ARTICLES, "project_id", project_id)
        return [self._compute_article_fields(r) for r in rows]

    # =======================================================================
    # Articles
    # =======================================================================

    @Slot(result="QVariant")
    def getArticles(self) -> list[dict]:
        projects = {p["id"]: p for p in self._db.get_all_rows(T_PROJECTS)}
        rows = self._db.get_all_rows(T_ARTICLES)
        return [self._enrich_article(r, projects) for r in rows]

    @Slot(int, result="QVariant")
    def getArticle(self, article_id: int):
        rows = self._db.get_rows_by_column(T_ARTICLES, "id", article_id)
        if not rows:
            return None
        return self._compute_article_fields(rows[0])

    @Slot("QVariant", result=int)
    def addArticle(self, data) -> int:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        new_id = self._db.insert_row(T_ARTICLES, _data)
        self.articlesChanged.emit()
        return new_id or -1

    @Slot(int, "QVariant", result=bool)
    def updateArticle(self, article_id: int, data) -> bool:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        ok = self._db.update_row(T_ARTICLES, article_id, _data)
        self.articlesChanged.emit()
        return ok

    @Slot(int, result=bool)
    def deleteArticle(self, article_id: int) -> bool:
        ok = self._db.delete_row(T_ARTICLES, article_id)
        self.articlesChanged.emit()
        return ok
