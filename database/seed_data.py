"""Script pour peupler les tables des modules Disinfection et WaterLift."""

from database.db import init_engine, DatabaseManager
from database.models import (
    DisinfectionTechno, DosingPump,
    Fluid, FlowUnit, WaterLift, Pipe, Accessory, ControlCabinet, WasteWaterPump
)

# Données pour T_DISINFECTION_TECHNO
DISINFECTION_TECHNO_DATA = [
    {"name": "Liquid Chlorine", "minCapacity": 0, "maxCapacity": 300},
    {"name": "Chlorine Gas", "minCapacity": 1, "maxCapacity": 4500},
    {"name": "Electrochlorination", "minCapacity": 125, "maxCapacity": 45000},
    {"name": "Chlorine Dioxyde", "minCapacity": 0, "maxCapacity": 2000},
]

# Données pour T_DOSING_PUMPS (quelques exemples)
DOSING_PUMPS_DATA = [
    {
        "name": "DDA 7.5-16 FCM",
        "control": "mA & pulse",
        "flowMonitoring": "yes",
        "installationKit": "not included",
        "maxFlow": 7.5,
        "minFlow": 0.0025,
        "maxPressure": 10,
        "designation": "DDA 7.5-16 FCM-PVC/V/C-F-31U2U2FG",
        "ref": "97722018"
    },
    {
        "name": "DDA 12-10 FCM",
        "control": "mA & pulse",
        "flowMonitoring": "yes",
        "installationKit": "not included",
        "maxFlow": 12,
        "minFlow": 0.012,
        "maxPressure": 10,
        "designation": "DDA 12-10 FCM-PVC/V/C-F-31U2U2FG",
        "ref": "97722120"
    },
    {
        "name": "DDA 17-7 FCM",
        "control": "mA & pulse",
        "flowMonitoring": "yes",
        "installationKit": "not included",
        "maxFlow": 17,
        "minFlow": 0.017,
        "maxPressure": 7,
        "designation": "DDA 17-7 FCM-PVC/V/C-F-31U2U2FG",
        "ref": "97722222"
    },
]

# Données pour T_FLUID
FLUID_DATA = [
    {"name": "Eau", "temperature": 20, "viscoDynamique": 1.0, "massVol": 1000},
    {"name": "Eau usée", "temperature": 20, "viscoDynamique": 1.1, "massVol": 1005},
]

# Données pour T_FLOW_UNIT
FLOW_UNIT_DATA = [
    {"name": "m3/h"},
    {"name": "l/s"},
]

# Données pour T_WATERLIFT (exemples)
WATERLIFT_DATA = [
    {"name": "DN50", "dnMaxPump": 50, "diam": 50},
    {"name": "DN80", "dnMaxPump": 80, "diam": 80},
    {"name": "DN100", "dnMaxPump": 100, "diam": 100},
]

# Données pour T_PIPE (exemples)
PIPE_DATA = [
    {"name": "Stainless DN50 PN10", "material": "Stainless", "r_pressure": 10, "r_nd": 50, "r_intDiam": 53, "r_ru": 0.14},
    {"name": "Stainless DN100 PN10", "material": "Stainless", "r_pressure": 10, "r_nd": 100, "r_intDiam": 98.3, "r_ru": 0.14},
    {"name": "PEHD110 PN10", "material": "PEHD", "r_pressure": 10, "r_nd": 100, "r_intDiam": 93.8, "r_ru": 0.015},
]

# Données pour T_ACCESSORIES
ACCESSORIES_DATA = [
    {"name": "Pump Connection", "r_zeta": 0.3},
    {"name": "90 elbow", "r_zeta": 0.5},
    {"name": "45 elbow", "r_zeta": 0.3},
    {"name": "T Connection", "r_zeta": 0.6},
    {"name": "No return valve", "r_zeta": 0.9},
    {"name": "Valve", "r_zeta": 0.5},
]

# Données pour T_CONTROL_CABINET (exemples)
CONTROL_CABINET_DATA = [
    {
        "type": "LC231",
        "name": "LC321-M",
        "height": 250,
        "width": 120,
        "depth": 100,
        "power": 0.9,
        "elecNetwork": "1 phase",
        "tension": 230,
        "iMax": 10,
        "NbPump": 1
    },
    {
        "type": "GCL",
        "name": "GCL-15-230T-10",
        "height": 250,
        "width": 120,
        "depth": 100,
        "power": 1.5,
        "elecNetwork": "3 phase",
        "tension": 230,
        "iMax": 12,
        "NbPump": 2
    },
]


def seed_database():
    """Peuple la base de données avec les données initiales."""
    print("Seeding database with module data...")
    
    # Initialiser la BDD
    init_engine(db_type="sqlite", path="sebae.db")
    db = DatabaseManager()
    
    # Vérifier si les tables existent déjà avec des données
    tables_to_seed = [
        (T_DISINFECTION_TECHNO, DISINFECTION_TECHNO_DATA, DisinfectionTechno),
        (T_DOSING_PUMPS, DOSING_PUMPS_DATA, DosingPump),
        (T_FLUID, FLUID_DATA, Fluid),
        (T_FLOW_UNIT, FLOW_UNIT_DATA, FlowUnit),
        (T_WATERLIFT, WATERLIFT_DATA, WaterLift),
        (T_PIPE, PIPE_DATA, Pipe),
        (T_ACCESSORIES, ACCESSORIES_DATA, Accessory),
        (T_CONTROL_CABINET, CONTROL_CABINET_DATA, ControlCabinet),
    ]
    
    for table_name, data_list, model_class in tables_to_seed:
        # Vérifier si la table a déjà des données
        existing = db.get_all_rows(table_name)
        if not existing:
            # Insérer les données
            for data in data_list:
                db.insert_row(table_name, data)
            print(f"Seeded {len(data_list)} rows into {table_name}")
        else:
            print(f"{table_name} already has {len(existing)} rows, skipping...")
    
    print("Database seeding complete!")


if __name__ == "__main__":
    seed_database()
