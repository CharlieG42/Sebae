"""Backend for Disinfection module."""
from __future__ import annotations
import logging
from PySide6.QtCore import QObject, Property, Signal, Slot
from database.db import DatabaseManager

logger = logging.getLogger(__name__)

T_TECHNO = "T_DISINFECTION_TECHNO"
T_PROJECTS = "T_DISINFECTION_PROJECTS"
T_INJECTION_POINTS = "T_DISINFECTION_INJECTION_POINTS"


class DisinfectionBackend(QObject):
    technologiesChanged = Signal()
    projectsChanged = Signal()
    injectionPointsChanged = Signal()

    def __init__(self):
        super().__init__()
        self._db = DatabaseManager()