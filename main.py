# This Python file uses the following encoding: utf-8
"""
Point d'entrée unique de MyHydraulicApp.
"""

import sys
import tomllib
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from database.db import init_engine
from database import models          # noqa: F401 — enregistre les modèles SQLModel
from backend.app_backend import Backend
from backend.maint_backend import MaintenanceBackend
from backend.biz_backend import BizBackend


def load_config() -> dict:
    config_path = Path(__file__).resolve().parent / "config.toml"
    with open(config_path, "rb") as f:
        return tomllib.load(f)


if __name__ == "__main__":

    config = load_config()
    db_cfg = config["database"]
    init_engine(db_type=db_cfg["type"], path=db_cfg["path"])

    app = QGuiApplication(sys.argv)

    engine = QQmlApplicationEngine()

    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)

    maintBackend = MaintenanceBackend()
    engine.rootContext().setContextProperty("maintBackend", maintBackend)

    bizBackend = BizBackend()
    engine.rootContext().setContextProperty("bizBackend", bizBackend)

    base_dir = Path(__file__).resolve().parent
    engine.load(base_dir / "qml" / "main.qml")

    if not engine.rootObjects():
        sys.exit(-1)

    engine.quit.connect(app.quit)
    sys.exit(app.exec())
