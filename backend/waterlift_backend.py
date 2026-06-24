"""Backend for WaterLift module."""
from __future__ import annotations
import logging
from PySide6.QtCore import QObject, Property, Signal, Slot
from database.db import DatabaseManager

logger = logging.getLogger(__name__)

T_PROJECTS = "T_WATERLIFT_PROJECTS"
T_PUMPS = "T_WATERLIFT_PUMPS"
T_ACCESS = "T_WATERLIFT_ACCESS"
T_CABINETS = "T_WATERLIFT_CABINETS"
T_PUMPING_STATIONS = "T_WATERLIFT_PUMPING_STATIONS"

FLUID_TYPES = [
    {"name": "Eau", "temperature": 20, "viscoDynam": 1.0, "massVol": 1000},
    {"name": "Eau de mer", "temperature": 15, "viscoDynam": 1.2, "massVol": 1025},
    {"name": "Eau chaude", "temperature": 60, "viscoDynam": 0.5, "massVol": 980},
]

INSTALLATION_TYPES = [
    {"text": "Espace Vert", "type": "espaceVert"},
    {"text": "Sous Chaussée", "type": "sousChaussee"},
]


class WaterLiftBackend(QObject):
    projectsChanged = Signal()
    pumpsChanged = Signal()
    accessChanged = Signal()
    cabinetsChanged = Signal()
    pumpingStationsChanged = Signal()

    def __init__(self):
        super().__init__()
        self._db = DatabaseManager()
        self._projects = []
        self._pumps = []
        self._access = []
        self._cabinets = []
        self._pumping_stations = []
        self._load_all()

    def _load_all(self):
        self._load_projects()
        self._load_pumps()
        self._load_access()
        self._load_cabinets()
        self._load_pumping_stations()

    @Property("QVariant", notify=projectsChanged)
    def projects(self):
        return self._projects

    @Property("QVariant", notify=pumpsChanged)
    def pumps(self):
        return self._pumps

    @Property("QVariant", notify=accessChanged)
    def access(self):
        return self._access

    @Property("QVariant", notify=cabinetsChanged)
    def cabinets(self):
        return self._cabinets

    @Property("QVariant", notify=pumpingStationsChanged)
    def pumpingStations(self):
        return self._pumping_stations

    def _load_projects(self):
        try:
            rows = self._db.get_all_rows(T_PROJECTS)
            self._projects = [{"id": p["id"], "project_no": p.get("project_no", ""), "name": p.get("name", ""), "altitude": float(p.get("altitude") or 0), "refoulLevel": float(p.get("refoulLevel") or 0), "flowRate": float(p.get("flowRate") or 0), "flowUnit": p.get("flowUnit", "m3/h")} for p in rows]
            self.projectsChanged.emit()
        except Exception as e:
            logger.error(f"Error loading WaterLift projects: {e}")

    def _load_pumps(self):
        try:
            rows = self._db.get_all_rows(T_PUMPS)
            self._pumps = [{"id": p["id"], "project_id": p.get("project_id"), "brand": p.get("brand", ""), "model": p.get("model", ""), "flowRate": float(p.get("flowRate") or 0), "head": float(p.get("head") or 0), "power": float(p.get("power") or 0)} for p in rows]
            self.pumpsChanged.emit()
        except Exception as e:
            logger.error(f"Error loading WaterLift pumps: {e}")

    def _load_access(self):
        try:
            rows = self._db.get_all_rows(T_ACCESS)
            self._access = [{"id": a["id"], "project_id": a.get("project_id"), "name": a.get("name", ""), "type": a.get("type", ""), "diameter": float(a.get("diameter") or 0), "length": float(a.get("length") or 0)} for a in rows]
            self.accessChanged.emit()
        except Exception as e:
            logger.error(f"Error loading WaterLift access: {e}")

    def _load_cabinets(self):
        try:
            rows = self._db.get_all_rows(T_CABINETS)
            self._cabinets = [{"id": c["id"], "project_id": c.get("project_id"), "name": c.get("name", ""), "power": float(c.get("power") or 0), "voltage": c.get("voltage", "")} for c in rows]
            self.cabinetsChanged.emit()
        except Exception as e:
            logger.error(f"Error loading WaterLift cabinets: {e}")

    def _load_pumping_stations(self):
        try:
            rows = self._db.get_all_rows(T_PUMPING_STATIONS)
            self._pumping_stations = [{"id": ps["id"], "project_id": ps.get("project_id"), "name": ps.get("name", ""), "location": ps.get("location", ""), "capacity": float(ps.get("capacity") or 0)} for ps in rows]
            self.pumpingStationsChanged.emit()
        except Exception as e:
            logger.error(f"Error loading WaterLift pumping stations: {e}")

    @Slot(result="QVariant")
    def getFluidTypes(self):
        return FLUID_TYPES

    @Slot(result="QVariant")
    def getInstallationTypes(self):
        return INSTALLATION_TYPES

    @Slot(result="QVariant")
    def getProjects(self):
        return self._projects

    @Slot(int, result="QVariant")
    def getProject(self, project_id):
        for proj in self._projects:
            if proj.get("id") == project_id:
                return proj
        return None

    @Slot("QVariant", result=int)
    def addProject(self, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            new_id = self._db.insert_row(T_PROJECTS, _data)
            self._load_projects()
            return new_id or -1
        except Exception as e:
            logger.error(f"Error adding WaterLift project: {e}")
            return -1

    @Slot(int, "QVariant", result=bool)
    def updateProject(self, project_id, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            ok = self._db.update_row(T_PROJECTS, project_id, _data)
            self._load_projects()
            return ok
        except Exception as e:
            logger.error(f"Error updating WaterLift project: {e}")
            return False

    @Slot(int, result=bool)
    def deleteProject(self, project_id):
        try:
            for pump in self._db.get_rows_by_column(T_PUMPS, "project_id", project_id):
                self._db.update_row(T_PUMPS, pump["id"], {"project_id": None})
            for acc in self._db.get_rows_by_column(T_ACCESS, "project_id", project_id):
                self._db.update_row(T_ACCESS, acc["id"], {"project_id": None})
            for cab in self._db.get_rows_by_column(T_CABINETS, "project_id", project_id):
                self._db.update_row(T_CABINETS, cab["id"], {"project_id": None})
            for ps in self._db.get_rows_by_column(T_PUMPING_STATIONS, "project_id", project_id):
                self._db.update_row(T_PUMPING_STATIONS, ps["id"], {"project_id": None})
            ok = self._db.delete_row(T_PROJECTS, project_id)
            self._load_all()
            return ok
        except Exception as e:
            logger.error(f"Error deleting WaterLift project: {e}")
            return False

    @Slot(int, result="QVariant")
    def getPumpsForProject(self, project_id):
        return [p for p in self._pumps if p.get("project_id") == project_id]

    @Slot("QVariant", result=int)
    def addPump(self, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            new_id = self._db.insert_row(T_PUMPS, _data)
            self._load_pumps()
            return new_id or -1
        except Exception as e:
            logger.error(f"Error adding WaterLift pump: {e}")
            return -1

    @Slot(int, "QVariant", result=bool)
    def updatePump(self, pump_id, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            ok = self._db.update_row(T_PUMPS, pump_id, _data)
            self._load_pumps()
            return ok
        except Exception as e:
            logger.error(f"Error updating WaterLift pump: {e}")
            return False

    @Slot(int, result=bool)
    def deletePump(self, pump_id):
        try:
            ok = self._db.delete_row(T_PUMPS, pump_id)
            self._load_pumps()
            return ok
        except Exception as e:
            logger.error(f"Error deleting WaterLift pump: {e}")
            return False

    @Slot(int, result="QVariant")
    def getAccessForProject(self, project_id):
        return [a for a in self._access if a.get("project_id") == project_id]

    @Slot("QVariant", result=int)
    def addAccess(self, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            new_id = self._db.insert_row(T_ACCESS, _data)
            self._load_access()
            return new_id or -1
        except Exception as e:
            logger.error(f"Error adding WaterLift access: {e}")
            return -1

    @Slot(int, "QVariant", result=bool)
    def updateAccess(self, access_id, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            ok = self._db.update_row(T_ACCESS, access_id, _data)
            self._load_access()
            return ok
        except Exception as e:
            logger.error(f"Error updating WaterLift access: {e}")
            return False

    @Slot(int, result=bool)
    def deleteAccess(self, access_id):
        try:
            ok = self._db.delete_row(T_ACCESS, access_id)
            self._load_access()
            return ok
        except Exception as e:
            logger.error(f"Error deleting WaterLift access: {e}")
            return False

    @Slot(int, result="QVariant")
    def getCabinetsForProject(self, project_id):
        return [c for c in self._cabinets if c.get("project_id") == project_id]

    @Slot("QVariant", result=int)
    def addCabinet(self, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            new_id = self._db.insert_row(T_CABINETS, _data)
            self._load_cabinets()
            return new_id or -1
        except Exception as e:
            logger.error(f"Error adding WaterLift cabinet: {e}")
            return -1

    @Slot(int, "QVariant", result=bool)
    def updateCabinet(self, cabinet_id, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            ok = self._db.update_row(T_CABINETS, cabinet_id, _data)
            self._load_cabinets()
            return ok
        except Exception as e:
            logger.error(f"Error updating WaterLift cabinet: {e}")
            return False

    @Slot(int, result=bool)
    def deleteCabinet(self, cabinet_id):
        try:
            ok = self._db.delete_row(T_CABINETS, cabinet_id)
            self._load_cabinets()
            return ok
        except Exception as e:
            logger.error(f"Error deleting WaterLift cabinet: {e}")
            return False

    @Slot(int, result="QVariant")
    def getPumpingStationsForProject(self, project_id):
        return [ps for ps in self._pumping_stations if ps.get("project_id") == project_id]

    @Slot("QVariant", result=int)
    def addPumpingStation(self, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            new_id = self._db.insert_row(T_PUMPING_STATIONS, _data)
            self._load_pumping_stations()
            return new_id or -1
        except Exception as e:
            logger.error(f"Error adding WaterLift pumping station: {e}")
            return -1

    @Slot(int, "QVariant", result=bool)
    def updatePumpingStation(self, ps_id, data):
        _data = data.toVariant() if hasattr(data, "toVariant") else data
        try:
            ok = self._db.update_row(T_PUMPING_STATIONS, ps_id, _data)
            self._load_pumping_stations()
            return ok
        except Exception as e:
            logger.error(f"Error updating WaterLift pumping station: {e}")
            return False

    @Slot(int, result=bool)
    def deletePumpingStation(self, ps_id):
        try:
            ok = self._db.delete_row(T_PUMPING_STATIONS, ps_id)
            self._load_pumping_stations()
            return ok
        except Exception as e:
            logger.error(f"Error deleting WaterLift pumping station: {e}")
            return False
