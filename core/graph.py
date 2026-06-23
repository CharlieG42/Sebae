# This Python file uses the following encoding: utf-8
"""
Génération de graphiques matplotlib sauvegardés en images PNG.
Compatible PySide6 : matplotlib est initialisé avec le backend Agg
(rendu fichier uniquement, pas de fenêtre Tk/Qt conflictuelle).
"""

from __future__ import annotations

import matplotlib
matplotlib.use("Agg")           # backend sans fenêtre — compatible PySide6
import matplotlib.pyplot as plt

from .pump import Pump


class Graph:
    """
    Graphique en courbes pour comparer deux pompes sur une plage d'années.

    Paramètres
    ----------
    pump1, pump2 : instances de Pump
    image_path   : chemin de sortie de l'image PNG
    title        : titre du graphique
    colors       : liste d'au moins 2 couleurs (ex. ["blue", "red"])
    title_x      : label de l'axe X
    data_x       : liste des valeurs X (ex. range(0, 16))
    title_y      : label de l'axe Y
    eff_loss     : perte de rendement annuelle appliquée dans les calculs (%)
    """

    def __init__(
        self,
        pump1:      Pump,
        pump2:      Pump,
        image_path: str,
        title:      str,
        colors:     list[str],
        title_x:    str,
        data_x,
        title_y:    str,
        eff_loss:   float = 1.0,
    ):
        self.pump1      = pump1
        self.pump2      = pump2
        self.image_path = image_path
        self.title      = title
        self.colors     = colors
        self.title_x    = title_x
        self.data_x     = list(data_x)
        self.title_y    = title_y
        self.eff_loss   = eff_loss
        self.data_y:    dict[str, list[float]] = {}

    # -------------------------------------------------------------------------

    def _degra_coef(self, idx: int) -> float:
        """Coefficient de dégradation cumulée à l'année idx."""
        return 1.0 / ((100 - idx * self.eff_loss) / 100)

    def prepare_power(
        self, *, label1: str, label2: str, time1: float, time2: float
    ) -> int:
        """
        Prépare les séries pour un graphique de puissance cumulée (MWh).
        Retourne l'écart de puissance annuelle (Wh) entre les deux pompes.
        """
        list1, list2 = [0.0], [0.0]

        for i, _ in enumerate(self.data_x[1:], start=1):
            coef = self._degra_coef(i)
            list1.append(list1[-1] + round(self.pump1.current_power() * time1 * coef / 1000, 2))
            list2.append(list2[-1] + round(self.pump2.current_power() * time2 * coef / 1000, 2))

        self.data_y = {label1: list1, label2: list2}
        return int((list1[1] - list2[1]) * 1000) if len(list1) > 1 else 0

    def prepare_cost(
        self,
        *,
        label1:       str,
        label2:       str,
        time1:        float,
        time2:        float,
        energy_cost:  float = 0.0,
        extra_cost1:  float = 0.0,
        extra_cost2:  float = 0.0,
    ) -> bool:
        """
        Prépare les séries pour un graphique de coût total cumulé (k€).
        extra_cost1/2 : investissement initial en k€.
        """
        list1: list[float] = [extra_cost1]
        list2: list[float] = [extra_cost2]

        for i, _ in enumerate(self.data_x[1:], start=1):
            coef = self._degra_coef(i)
            list1.append(list1[-1] + round(self.pump1.current_power() * time1 * energy_cost * coef / 1000, 2))
            list2.append(list2[-1] + round(self.pump2.current_power() * time2 * energy_cost * coef / 1000, 2))

        self.data_y = {label1: list1, label2: list2}
        return True

    def line(self) -> str:
        """Génère et sauvegarde le graphique en courbes. Retourne le chemin de l'image."""
        fig, ax = plt.subplots()

        for idx, (label, values) in enumerate(self.data_y.items()):
            color = self.colors[idx] if idx < len(self.colors) else None
            ax.plot(self.data_x, values, label=label, color=color)

        ax.set_title(self.title)
        ax.set_xlabel(self.title_x)
        ax.set_ylabel(self.title_y)
        ax.legend()
        ax.grid(True)

        fig.savefig(self.image_path)
        plt.close(fig)

        return self.image_path

    # --- Alias camelCase pour compatibilité avec l'ancien code ---
    def prepareGraphPower(self, *, title1, title2, timeP1, timeP2) -> int:
        return self.prepare_power(label1=title1, label2=title2, time1=timeP1, time2=timeP2)

    def prepareGraphCost(self, *, title1, title2, timeP1, timeP2,
                         energyCost=0, extraCostP1=0, extraCostP2=0) -> bool:
        return self.prepare_cost(
            label1=title1, label2=title2, time1=timeP1, time2=timeP2,
            energy_cost=energyCost, extra_cost1=extraCostP1, extra_cost2=extraCostP2,
        )
