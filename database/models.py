# This Python file uses the following encoding: utf-8
"""
Modèles SQLModel de l'application.
Chaque classe correspond à une table dans la base de données.
"""

from __future__ import annotations
from typing import Optional
from sqlmodel import Field, SQLModel


class Pump(SQLModel, table=True):
    __tablename__ = "T_PUMPS"

    id:            Optional[int]   = Field(default=None, primary_key=True)
    BRAND:         str
    NAME:          str
    NOMINAL_FLOW:  Optional[float] = None
    NOMINAL_HEAD:  Optional[float] = None
    NOMINAL_POWER: Optional[float] = None
    EFF_PUMP:      Optional[float] = None
    EFF_MOTOR:     Optional[float] = None
    PN:            Optional[str]   = None


class Project(SQLModel, table=True):
    __tablename__ = "T_PROJECTS"

    id:        Optional[int]   = Field(default=None, primary_key=True)
    NAME:      str
    CUSTOMER:  Optional[str]   = None
    SALES_REP: Optional[str]   = None
    PUMP1:     Optional[str]   = None   # JSON sérialisé
    PUMP2:     Optional[str]   = None   # JSON sérialisé
    NRJ_COST:  Optional[float] = None
    CO2_COEF:  Optional[float] = None


class Customer(SQLModel, table=True):
    __tablename__ = "T_CUSTOMERS"

    id:     Optional[int] = Field(default=None, primary_key=True)
    name:   str           = Field(unique=True)
    crm_id: Optional[str] = None


# ============================================================
# Module Contrats d'entretien
# ============================================================

class ContractType(SQLModel, table=True):
    """
    Définit le contenu d'un type de contrat (Bronze / Argent / Or).
    Modifiable par l'utilisateur depuis la fenêtre Paramètres.
    """
    __tablename__ = "T_CONTRACT_TYPES"

    id:           Optional[int]   = Field(default=None, primary_key=True)
    name:         str             = Field(unique=True)   # "Bronze", "Argent", "Or"
    nb_visits:    Optional[int]   = None    # nb de visites d'entretien / an
    response_time_h: Optional[int] = None   # délai d'intervention garanti (heures)
    discount_pct: Optional[float] = None    # remise pièces détachées (%)
    base_price:   Optional[float] = None    # prix de base annuel (€)
    description:  Optional[str]   = None    # texte libre — détail des prestations
    color:        Optional[str]   = None    # couleur d'affichage (ex. "#CD7F32")


class MaintClient(SQLModel, table=True):
    """Client du module Contrats d'entretien."""
    __tablename__ = "T_MAINT_CLIENTS"

    id:      Optional[int] = Field(default=None, primary_key=True)
    name:    str
    id_c4c:  Optional[str] = None   # identifiant CRM (C4C)


class MaintContact(SQLModel, table=True):
    """Contact rattaché à un client."""
    __tablename__ = "T_MAINT_CONTACTS"

    id:         Optional[int] = Field(default=None, primary_key=True)
    last_name:  str
    first_name: Optional[str] = None
    email:      Optional[str] = None
    mobile:     Optional[str] = None
    client_id:  Optional[int] = Field(default=None, foreign_key="T_MAINT_CLIENTS.id")


class MaintContract(SQLModel, table=True):
    """Contrat d'entretien."""
    __tablename__ = "T_MAINT_CONTRACTS"

    id:           Optional[int]   = Field(default=None, primary_key=True)
    contract_no:  str             = Field(unique=True)   # numéro de contrat
    client_id:    Optional[int]   = Field(default=None, foreign_key="T_MAINT_CLIENTS.id")
    contact_id:   Optional[int]   = Field(default=None, foreign_key="T_MAINT_CONTACTS.id")
    contract_type:Optional[str]   = None   # "Bronze" / "Argent" / "Or"
    start_date:   Optional[str]   = None   # ISO 8601 (YYYY-MM-DD)
    end_date:     Optional[str]   = None
    cost:         Optional[float] = None
    status:       Optional[str]   = "en préparation"   # actif / inactif / en préparation


class MaintMachine(SQLModel, table=True):
    """Machine du parc, rattachée à un contrat."""
    __tablename__ = "T_MAINT_MACHINES"

    id:          Optional[int]   = Field(default=None, primary_key=True)
    brand:       str
    type:        Optional[str]   = None
    reference:   Optional[str]   = None
    build_year:  Optional[int]   = None
    location:    Optional[str]   = None
    contract_id: Optional[int]   = Field(default=None, foreign_key="T_MAINT_CONTRACTS.id")


# ============================================================
# Module Projet
# ============================================================

class BizProject(SQLModel, table=True):
    """Projet commercial — réutilise T_MAINT_CLIENTS et T_MAINT_CONTACTS."""
    __tablename__ = "T_BIZ_PROJECTS"

    id:          Optional[int] = Field(default=None, primary_key=True)
    project_no:  str           = Field(unique=True)   # numéro d'identification du projet
    name:        str                                  # nom du projet
    city:        Optional[str] = None                 # ville du projet
    client_id:   Optional[int] = Field(default=None, foreign_key="T_MAINT_CLIENTS.id")
    contact_id:  Optional[int] = Field(default=None, foreign_key="T_MAINT_CONTACTS.id")


class BizArticle(SQLModel, table=True):
    """
    Article / ligne d'un projet.

    Champs calculés (non stockés en base, recalculés à l'usage) :
      PCTM  = (sale_price - total_cost) * quantity
      PCTR  = PCTM / sale_price * 100
      GRPi  = sale_price * 100 / grp
    """
    __tablename__ = "T_BIZ_ARTICLES"

    id:           Optional[int]   = Field(default=None, primary_key=True)
    article_no:   str             = Field(unique=True)   # numéro d'identification de l'article
    project_id:   Optional[int]   = Field(default=None, foreign_key="T_BIZ_PROJECTS.id")
    designation:  str                                     # désignation
    article_type: Optional[str]   = None   # "Produit" / "Prestation interne" / "Prestation externe" / "Achat externe"
    quantity:     Optional[float] = 1.0
    total_cost:   Optional[float] = 0.0    # coût total de l'article
    sale_price:   Optional[float] = 0.0    # prix de vente prévu
    grp:          Optional[float] = None   # prix fixe spécifique au produit (saisi)
    mpg:          Optional[str]   = None   # code à 2 lettres
