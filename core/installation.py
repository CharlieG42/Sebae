# This Python file uses the following encoding: utf-8
"""
Représente une installation complète (pompe + contexte d'exploitation).
Regroupe les notions d'heures de fonctionnement, de coût et de mode de régulation.
"""

from __future__ import annotations
from .pump import Pump


class Installation:
    """
    Association d'une pompe et de ses conditions d'exploitation.

    Paramètres
    ----------
    pump            : instance de Pump
    hours           : heures de fonctionnement annuelles
    energy_cost     : coût du kWh en €/kWh
    regulation_mode : mode de régulation (ex. "vitesse variable", "tout-ou-rien")
    initial_cost    : coût d'investissement initial en €
    """

    # Coefficient d'économie selon le mode de régulation (à affiner)
    _REGULATION_COEF: dict[str, float] = {
        "vitesse variable": 0.70,   # économie typique : ~30 %
        "tout-ou-rien":     1.00,
        "":                 1.00,
    }

    def __init__(
        self,
        pump:            Pump,
        hours:           float,
        energy_cost:     float,
        regulation_mode: str   = "",
        initial_cost:    float = 0.0,
    ):
        self.pump            = pump
        self.hours           = float(hours)
        self.energy_cost     = float(energy_cost)
        self.regulation_mode = regulation_mode
        self.initial_cost    = float(initial_cost)

    # -------------------------------------------------------------------------

    def regulation_effect(self) -> float:
        """Coefficient multiplicateur lié au mode de régulation (≤ 1)."""
        return self._REGULATION_COEF.get(self.regulation_mode.lower(), 1.0)

    def annual_energy_cost(self) -> float:
        """Coût énergétique annuel en €, après application du mode de régulation."""
        return (
            self.pump.current_power()
            * self.energy_cost
            * self.hours
            * self.regulation_effect()
        )

    def global_cost(self, years: int) -> float:
        """
        Coût total sur une période donnée (investissement + énergie cumulée) en €.

        Paramètres
        ----------
        years : nombre d'années considérées
        """
        return self.initial_cost + self.annual_energy_cost() * years
