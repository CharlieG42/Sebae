# This Python file uses the following encoding: utf-8
"""
Couche base de données unifiée.
Supporte SQLite (défaut) et Microsoft Access via SQLAlchemy.
Tout le reste du code utilise uniquement DatabaseManager,
jamais le moteur directement.
"""

from __future__ import annotations

from typing import Any

from sqlalchemy import (
    create_engine, inspect, MetaData, Table,
    select, insert, update, delete,
)
from sqlalchemy.engine import Engine
from sqlmodel import SQLModel


# ---------------------------------------------------------------------------
# Singleton engine
# ---------------------------------------------------------------------------

_engine: Engine | None = None


def init_engine(db_type: str = "sqlite", path: str = "myapp.db") -> Engine:
    """
    Initialise l'engine SQLAlchemy.
    À appeler une seule fois au démarrage (main.py).
    """
    global _engine

    if db_type == "sqlite":
        _engine = create_engine(
            f"sqlite:///{path}",
            echo=False,
            connect_args={"check_same_thread": False},  # requis avec PySide6
        )
    elif db_type == "access":
        conn_str = (
            r"DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};"
            f"DBQ={path};"
        )
        _engine = create_engine(
            f"access+pyodbc:///?odbc_connect={conn_str}",
            echo=False,
        )
    else:
        raise ValueError(f"Type de BDD non supporté : '{db_type}'")

    # Crée les tables définies dans les modèles SQLModel (no-op si déjà présentes)
    SQLModel.metadata.create_all(_engine)

    return _engine


def get_engine() -> Engine:
    if _engine is None:
        raise RuntimeError("init_engine() doit être appelé avant get_engine().")
    return _engine


# ---------------------------------------------------------------------------
# DatabaseManager — opérations génériques sur n'importe quelle table
# ---------------------------------------------------------------------------

class DatabaseManager:
    """
    Accès générique aux tables, indépendant des modèles SQLModel.
    Utilisé par la fenêtre Admin et par les slots métier du backend.
    """

    def __init__(self):
        self.engine = get_engine()

    # --- Introspection -------------------------------------------------------

    def get_table_names(self) -> list[str]:
        """Retourne la liste de toutes les tables de la BDD."""
        return inspect(self.engine).get_table_names()

    def get_columns(self, table_name: str) -> list[str]:
        """Retourne les noms de colonnes d'une table."""
        return [
            col["name"]
            for col in inspect(self.engine).get_columns(table_name)
        ]

    # --- Lecture -------------------------------------------------------------

    def get_all_rows(self, table_name: str) -> list[dict]:
        """Retourne toutes les lignes d'une table sous forme de liste de dicts."""
        meta  = MetaData()
        table = Table(table_name, meta, autoload_with=self.engine)
        cols  = [c.key for c in table.columns]
        with self.engine.connect() as conn:
            rows = conn.execute(select(table)).fetchall()
        return [dict(zip(cols, row)) for row in rows]

    def get_rows_by_column(self, table_name: str, column: str, value: Any) -> list[dict]:
        """Retourne les lignes filtrées sur une colonne."""
        meta  = MetaData()
        table = Table(table_name, meta, autoload_with=self.engine)
        cols  = [c.key for c in table.columns]
        with self.engine.connect() as conn:
            stmt = select(table).where(table.c[column] == value)
            rows = conn.execute(stmt).fetchall()
        return [dict(zip(cols, row)) for row in rows]

    # --- Écriture ------------------------------------------------------------

    def insert_row(self, table_name: str, data: dict) -> int | None:
        """Insère une ligne et retourne son id généré."""
        meta  = MetaData()
        table = Table(table_name, meta, autoload_with=self.engine)
        with self.engine.connect() as conn:
            result = conn.execute(insert(table).values(data))
            conn.commit()
        return result.inserted_primary_key[0] if result.inserted_primary_key else None

    def update_row(self, table_name: str, row_id: int, data: dict) -> bool:
        """Met à jour une ligne identifiée par son id."""
        meta  = MetaData()
        table = Table(table_name, meta, autoload_with=self.engine)
        with self.engine.connect() as conn:
            conn.execute(update(table).where(table.c.id == row_id).values(data))
            conn.commit()
        return True

    def delete_row(self, table_name: str, row_id: int) -> bool:
        """Supprime une ligne identifiée par son id."""
        meta  = MetaData()
        table = Table(table_name, meta, autoload_with=self.engine)
        with self.engine.connect() as conn:
            conn.execute(delete(table).where(table.c.id == row_id))
            conn.commit()
        return True
