# This Python file uses the following encoding: utf-8
"""
Calculs hydrauliques.
  - CalcJ      : pertes de charge linéaires (Swamee-Jain)
  - CalcNPSHd  : pression nette d'aspiration disponible
"""

from __future__ import annotations
import math


class CalcJ:
    """
    Calcul de la perte de charge linéaire J (mm/m) par la formule de Swamee-Jain.

    Paramètres
    ----------
    flow : débit en m³/h
    diam : diamètre intérieur en mm
    ru   : rugosité absolue en mm (défaut 0.01 mm — acier commercial)
    """

    def __init__(self, flow: float, diam: float, ru: float = 0.01):
        self.flow = float(flow) if flow and flow != 0 else 0.1
        self.diam = float(diam) if diam and diam != 0 else 0.1
        self.ru   = float(ru)   if ru   and ru   != 0 else 0.01

    # --- étapes intermédiaires ----------------------------------------------

    def _velocity(self) -> float:
        """Vitesse d'écoulement en m/s."""
        return self.flow * 4 / (3600 * math.pi * (self.diam * 1e-3) ** 2)

    def _v2_2g(self) -> float:
        return self._velocity() ** 2 / (2 * 9.81)

    def _reynolds(self) -> float:
        """Nombre de Reynolds (ν ≈ 1e-6 m²/s pour l'eau à 20 °C)."""
        return self._velocity() * (self.diam * 1e-3) / 1e-6

    def _friction(self) -> float:
        """Coefficient de frottement de Swamee-Jain."""
        A = 5.74 / self._reynolds() ** 0.9
        B = self.ru / (3.7 * self.diam)
        C = math.log10(A + B)
        return 0.25 / C ** 2

    def calc_j(self) -> float:
        """Retourne J en mm/m."""
        return self._friction() * self._v2_2g() * 1000 / (self.diam * 1e-3)

    # Alias conservé pour compatibilité avec l'ancien code
    def calcJ(self) -> float:
        return self.calc_j()


class CalcNPSHd:
    """
    Calcul du NPSHd (Net Positive Suction Head disponible) en mce.

    Paramètres
    ----------
    altitude    : altitude du site en m (influence la pression atmosphérique)
    length      : longueur de la conduite d'aspiration en m
    height      : hauteur d'aspiration géométrique en m (positive = aspiration)
    diam        : diamètre intérieur de la conduite en mm
    flowrate    : débit en m³/h
    temperature : température du fluide en °C (défaut 20 °C)
    """

    def __init__(
        self,
        altitude:    float,
        length:      float,
        height:      float,
        diam:        float,
        flowrate:    float,
        temperature: float = 20.0,
    ):
        def _to_float(v) -> float:
            return float(v) if v != "" else 0.0

        self.altitude    = _to_float(altitude)
        self.length      = _to_float(length)
        self.height      = _to_float(height)
        self.diam        = _to_float(diam)
        self.flowrate    = _to_float(flowrate)
        self.temperature = _to_float(temperature)

        # Pression atmosphérique en mce selon l'altitude
        self.atm_mce = round(10.33 - self.altitude * 1.16 / 1000, 2)

        # Perte de charge sur l'aspiration
        self.j_value = CalcJ(self.flowrate, self.diam).calc_j()

        # Pression de vapeur saturante en mce
        T_K = self.temperature + 273.15
        if self.temperature < 101:
            pv_bar = 10 ** (13.7 - 5120 / T_K) * 10   # Wikipedia formule approchée
        else:
            pv_bar = (self.temperature / 100) ** 4 * 10
        self.vapor_pressure = round(pv_bar, 2)

    def calc_npshd(self) -> float:
        """Retourne le NPSHd en mce."""
        return round(
            self.atm_mce
            + self.height
            - self.j_value * self.length / 1000
            - self.vapor_pressure,
            2,
        )
