import pytest
from pathlib import Path
import tempfile
import os


@pytest.fixture
def tmp_db_path(tmp_path):
    """Create a temporary database file path."""
    db_file = tmp_path / "test.db"
    return str(db_file)


@pytest.fixture
def tmp_config(tmp_path):
    """Create a temporary config.toml file."""
    config_path = tmp_path / "config.toml"
    config_content = f"""[app]
name = "Sebae Test"
version = "0.2.0"

[database]
type = "sqlite"
path = "{tmp_path / "test.db"}"

[admin]
login = "admin"
password_sha = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"
"""
    config_path.write_text(config_content)
    return str(config_path)