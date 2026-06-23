"""Tests for core module."""
import pytest
from core.pump import Pump
from core.hydraulics import CalcJ, CalcNPSHd
from core.installation import Installation


class TestPump:
    def test_init_eff(self):

        pump = Pump(eff_pump=80, eff_motor=90, eff_loss=1, flowrate=100, head=20, years=0)
        assert abs(pump.init_eff() - 72.0) < 0.01