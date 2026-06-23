# This Python file uses the following encoding: utf-8
"""
Modèle métier d'une pompe installée.
Calcule l'efficacité, la puissance et le coût énergétique
en tenant compte de la dégradation au fil des années.
"""

from __future__ import annotations

_EFF_DEGRA_MAX = 10.0   # Perte d'efficacité maximale prise en compte : 10 %


class Pump:
    """
    Représente une pompe en service.

    Paramètres
    ----------
    eff_pump   : rendement pompe initial en %
    eff_motor  : rendement moteur initial en %
    eff_loss   : perte de rendement annuelle en % (ex. 1 → 1 %/an)
    flowrate   : débit nominal en m³/h
    head       : HMT nominale en mce
    years      : nombre d'années en service
    """

    def __init__(
        self,
        eff_pump:  float,
        eff_motor: float,
        eff_loss:  float,
        flowrate:  float,
        head:      float,
        years:     int,
    ):
        self.eff_pump  = float(eff_pump)
        self.eff_motor = float(eff_motor)
        self.eff_loss  = float(eff_loss)
        self.flowrate  = float(flowrate)
        self.head      = float(head)
        self.years     = int(years)

    # -------------------------------------------------------------------------

    def init_eff(self) -> float:
        """Rendement global initial (pompe × moteur) en %."""
        return (self.eff_pump / 100) * (self.eff_motor / 100) * 100

    def current_eff(self) -> float:
        """Rendement global actuel, plafonné à init_eff - _EFF_DEGRA_MAX."""
        _init = self.init_eff()
        _current = _init * (1 - self.eff_loss / 100) ** self.years
        if _init - _current > _EFF_DEGRA_MAX:
            _current = _init - _EFF_DEGRA_MAX
        return _current

    def init_power(self) -> float:
        """Puissance absorbée initiale en kW."""
        return (self.flowrate * self.head) / (367 * (self.init_eff() / 100))

    def current_power(self) -> float:
        """Puissance absorbée actuelle en kW."""
        return (self.flowrate * self.head) / (367 * (self.current_eff() / 100))

    def annual_energy_cost(self, *, energy_cost: float, time: float) -> float:
        """
        Coût énergétique annuel en €.

        Paramètres
        ----------
        energy_cost : coût du kWh en €/kWh
        time        : durée de fonctionnement annuelle en heures
        """
        return self.current_power() * energy_cost * time

    # --- Alias snake_case / camelCase pour compatibilité ---
    def initEff(self)     -> float: return self.init_eff()
    def currentEff(self)  -> float: return self.current_eff()
    def initPower(self)   -> float: return self.init_power()
    def currentPower(self) -> float: return self.current_power()
