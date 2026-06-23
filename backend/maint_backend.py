# This Python file uses the following encoding: utf-8
"""
Backend du module "Contrats d'entretien".
Expose à QML : CRUD complet sur Contrats, Clients, Contacts, Machines,
ainsi que la gestion des types de contrat (Bronze/Argent/Or).

Convention de nommage : tous les slots renvoient des données déjà
"aplaties" en liste de dicts, prêtes pour un TableView / Repeater QML.
"""

from __future__ import annotations

from typing import Any

from PySide6.QtCore import QObject, Property, Signal, Slot

from database.db import DatabaseManager


# ---------------------------------------------------------------------------
# Tables gérées par ce backend
# ---------------------------------------------------------------------------

T_CONTRACTS = "T_MAINT_CONTRACTS"
T_CLIENTS   = "T_MAINT_CLIENTS"
T_CONTACTS  = "T_MAINT_CONTACTS"
T_MACHINES  = "T_MAINT_MACHINES"
T_TYPES     = "T_CONTRACT_TYPES"

_DEFAULT_TYPES = [
    {"name": "Bronze", "nb_visits": 1, "response_time_h": 72, "discount_pct": 0,
     "base_price": 500,  "description": "Visite annuelle. Diagnostic de base.",
     "color": "#CD7F32"},
    {"name": "Argent",  "nb_visits": 2, "response_time_h": 48, "discount_pct": 5,
     "base_price": 950,  "description": "2 visites/an. Pièces d'usure incluses.",
     "color": "#C0C0C0"},
    {"name": "Or",      "nb_visits": 4, "response_time_h": 24, "discount_pct": 15,
     "base_price": 1800, "description": "4 visites/an. Intervention prioritaire 24h. "
                                         "Pièces et main d'œuvre incluses.",
     "color": "#FFD700"},
]


class MaintenanceBackend(QObject):

    contractsChanged = Signal()
    clientsChanged    = Signal()
    contactsChanged   = Signal()
    machinesChanged   = Signal()
    typesChanged      = Signal()
    errorOccurred     = Signal(str)

    def __init__(self):
        super().__init__()
        self._db = DatabaseManager()
        self._ensure_default_types()

    # =======================================================================
    # Initialisation des types de contrat par défaut
    # =======================================================================

    def _ensure_default_types(self):
        existing = {row["name"] for row in self._db.get_all_rows(T_TYPES)}
        for t in _DEFAULT_TYPES:
            if t["name"] not in existing:
                self._db.insert_row(T_TYPES, t)

    # =======================================================================
    # Helpers internes
    # =======================================================================

    @staticmethod
    def _client_label(client: dict | None) -> str:
        if not client:
            return ""
        c4c = client.get("id_c4c") or ""
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
    def _contract_label(contract: dict | None, client_label: str = "") -> str:
        if not contract:
            return ""
        no = contract.get("contract_no") or ""
        return f"{no} - {client_label}" if client_label else no

    def _enrich_contract(self, row: dict, clients_by_id: dict, contacts_by_id: dict) -> dict:
        client  = clients_by_id.get(row.get("client_id"))
        contact = contacts_by_id.get(row.get("contact_id"))
        row["client_name"]   = client["name"] if client else ""
        row["client_label"]  = self._client_label(client)
        row["contact_name"]  = self._contact_label(contact)
        return row

    def _enrich_machine(self, row: dict, contracts_by_id: dict, clients_by_id: dict) -> dict:
        contract = contracts_by_id.get(row.get("contract_id"))
        client_label = self._client_label(clients_by_id.get(contract["client_id"])) if contract else ""
        row["contract_no"]    = contract["contract_no"] if contract else ""
        row["contract_label"] = self._contract_label(contract, client_label)
        return row

    def _enrich_contact(self, row: dict, clients_by_id: dict) -> dict:
        client = clients_by_id.get(row.get("client_id"))
        row["client_name"]  = client["name"] if client else ""
        row["client_label"] = self._client_label(client)
        return row

    # =======================================================================
    # Types de contrat (Bronze / Argent / Or) — Paramètres
    # =======================================================================

    @Slot(result="QVariant")
    def getContractTypes(self) -> list[dict]:
        return self._db.get_all_rows(T_TYPES)

    @Slot(int, "QVariant", result=bool)
    def updateContractType(self, type_id: int, data) -> bool:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        ok = self._db.update_row(T_TYPES, type_id, _data)
        self.typesChanged.emit()
        return ok

    @Slot("QVariant", result=int)
    def addContractType(self, data) -> int:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        new_id = self._db.insert_row(T_TYPES, _data)
        self.typesChanged.emit()
        return new_id or -1

    @Slot(int, result=bool)
    def deleteContractType(self, type_id: int) -> bool:
        ok = self._db.delete_row(T_TYPES, type_id)
        self.typesChanged.emit()
        return ok

    # =======================================================================
    # Clients
    # =======================================================================

    @Slot(result="QVariant")
    def getClients(self) -> list[dict]:
        return self._db.get_all_rows(T_CLIENTS)

    @Slot(int, result="QVariant")
    def getClient(self, client_id: int):
        rows = self._db.get_rows_by_column(T_CLIENTS, "id", client_id)
        return rows[0] if rows else None

    @Slot("QVariant", result=int)
    def addClient(self, data) -> int:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        new_id = self._db.insert_row(T_CLIENTS, _data)
        self.clientsChanged.emit()
        return new_id or -1

    @Slot(int, "QVariant", result=bool)
    def updateClient(self, client_id: int, data) -> bool:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        ok = self._db.update_row(T_CLIENTS, client_id, _data)
        self.clientsChanged.emit()
        return ok

    @Slot(int, result=bool)
    def deleteClient(self, client_id: int) -> bool:
        ok = self._db.delete_row(T_CLIENTS, client_id)
        self.clientsChanged.emit()
        return ok

    @Slot(result="QVariant")
    def getClientOptions(self) -> list[dict]:
        """Retourne [{id, label}] — label au format '<ID_C4C> - <Nom>'."""
        clients = self._db.get_all_rows(T_CLIENTS)
        return [{"id": c["id"], "label": self._client_label(c)} for c in clients]

    # =======================================================================
    # Contacts
    # =======================================================================

    @Slot(result="QVariant")
    def getContacts(self) -> list[dict]:
        clients = {c["id"]: c for c in self._db.get_all_rows(T_CLIENTS)}
        rows = self._db.get_all_rows(T_CONTACTS)
        return [self._enrich_contact(r, clients) for r in rows]

    @Slot(result="QVariant")
    def getContactOptions(self) -> list[dict]:
        """Retourne [{id, label}] — label au format '<Prénom> <Nom>'."""
        contacts = self._db.get_all_rows(T_CONTACTS)
        return [{"id": c["id"], "label": self._contact_label(c)} for c in contacts]

    @Slot(int, result="QVariant")
    def getContactOptionsForClient(self, client_id: int) -> list[dict]:
        """Retourne [{id, label}] filtré sur un client donné."""
        contacts = self._db.get_rows_by_column(T_CONTACTS, "client_id", client_id)
        return [{"id": c["id"], "label": self._contact_label(c)} for c in contacts]

    @Slot(int, result="QVariant")
    def getContact(self, contact_id: int):
        rows = self._db.get_rows_by_column(T_CONTACTS, "id", contact_id)
        return rows[0] if rows else None

    @Slot("QVariant", result=int)
    def addContact(self, data) -> int:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        new_id = self._db.insert_row(T_CONTACTS, _data)
        self.contactsChanged.emit()
        return new_id or -1

    @Slot(int, "QVariant", result=bool)
    def updateContact(self, contact_id: int, data) -> bool:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        ok = self._db.update_row(T_CONTACTS, contact_id, _data)
        self.contactsChanged.emit()
        return ok

    @Slot(int, result=bool)
    def deleteContact(self, contact_id: int) -> bool:
        ok = self._db.delete_row(T_CONTACTS, contact_id)
        self.contactsChanged.emit()
        return ok

    # =======================================================================
    # Contrats
    # =======================================================================

    @Slot(result="QVariant")
    def getContracts(self) -> list[dict]:
        clients  = {c["id"]: c for c in self._db.get_all_rows(T_CLIENTS)}
        contacts = {c["id"]: c for c in self._db.get_all_rows(T_CONTACTS)}
        rows = self._db.get_all_rows(T_CONTRACTS)
        return [self._enrich_contract(r, clients, contacts) for r in rows]

    @Slot(result="QVariant")
    def getContractOptions(self) -> list[dict]:
        """Retourne [{id, label}] — label au format '<N° contrat> - <ID_C4C> - <Nom>'."""
        clients   = {c["id"]: c for c in self._db.get_all_rows(T_CLIENTS)}
        contracts = self._db.get_all_rows(T_CONTRACTS)
        options = []
        for c in contracts:
            client_label = self._client_label(clients.get(c.get("client_id")))
            options.append({"id": c["id"], "label": self._contract_label(c, client_label)})
        return options

    @Slot(int, result="QVariant")
    def getContract(self, contract_id: int):
        rows = self._db.get_rows_by_column(T_CONTRACTS, "id", contract_id)
        return rows[0] if rows else None

    @Slot("QVariant", result=int)
    def addContract(self, data) -> int:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        new_id = self._db.insert_row(T_CONTRACTS, _data)
        self.contractsChanged.emit()
        return new_id or -1

    @Slot(int, "QVariant", result=bool)
    def updateContract(self, contract_id: int, data) -> bool:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        ok = self._db.update_row(T_CONTRACTS, contract_id, _data)
        self.contractsChanged.emit()
        return ok

    @Slot(int, result=bool)
    def deleteContract(self, contract_id: int) -> bool:
        # Détache les machines liées avant suppression (intégrité)
        for m in self._db.get_rows_by_column(T_MACHINES, "contract_id", contract_id):
            self._db.update_row(T_MACHINES, m["id"], {"contract_id": None})
        ok = self._db.delete_row(T_CONTRACTS, contract_id)
        self.contractsChanged.emit()
        self.machinesChanged.emit()
        return ok

    @Slot(int, result="QVariant")
    def getMachinesForContract(self, contract_id: int) -> list[dict]:
        return self._db.get_rows_by_column(T_MACHINES, "contract_id", contract_id)

    # =======================================================================
    # Machines (parc machine)
    # =======================================================================

    @Slot(result="QVariant")
    def getMachines(self) -> list[dict]:
        contracts = {c["id"]: c for c in self._db.get_all_rows(T_CONTRACTS)}
        clients   = {c["id"]: c for c in self._db.get_all_rows(T_CLIENTS)}
        rows = self._db.get_all_rows(T_MACHINES)
        return [self._enrich_machine(r, contracts, clients) for r in rows]

    @Slot(int, result="QVariant")
    def getMachine(self, machine_id: int):
        rows = self._db.get_rows_by_column(T_MACHINES, "id", machine_id)
        return rows[0] if rows else None

    @Slot("QVariant", result=int)
    def addMachine(self, data) -> int:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        new_id = self._db.insert_row(T_MACHINES, _data)
        self.machinesChanged.emit()
        return new_id or -1

    @Slot(int, "QVariant", result=bool)
    def updateMachine(self, machine_id: int, data) -> bool:
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        ok = self._db.update_row(T_MACHINES, machine_id, _data)
        self.machinesChanged.emit()
        return ok

    @Slot(int, result=bool)
    def deleteMachine(self, machine_id: int) -> bool:
        ok = self._db.delete_row(T_MACHINES, machine_id)
        self.machinesChanged.emit()
        return ok
