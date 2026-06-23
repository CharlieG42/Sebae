"""Pydantic schemas for input validation in Sebae."""

from pydantic import BaseModel, Field, validator
from typing import Optional


class PumpSchema(BaseModel):
    """Schema for Pump validation."""
    eff_pump: float = Field(..., gt=0, le=100, description="Pump efficiency (%)")
    eff_motor: float = Field(..., gt=0, le=100, description="Motor efficiency (%)")
    eff_loss: float = Field(..., ge=0, description="Annual efficiency loss (%)")
    flowrate: float = Field(..., gt=0, description="Nominal flow rate (m3/h)")
    head: float = Field(..., gt=0, description="Nominal head (mce)")
    years: int = Field(..., ge=0, description="Years in service")

    @validator('eff_pump', 'eff_motor')
    def check_efficiency(cls, v):
        if v > 100:
            raise ValueError("Efficiency cannot exceed 100%")
        return v


class HydraulicsSchema(BaseModel):
    """Schema for hydraulics calculations."""
    flow: float = Field(..., gt=0, description="Flow rate (m3/h)")
    diam: float = Field(..., gt=0, description="Diameter (mm)")
    ru: float = Field(default=0.01, ge=0, description="Roughness (mm)")


class InstallationSchema(BaseModel):
    """Schema for installation validation."""
    hours: float = Field(..., gt=0, description="Annual operating hours")
    energy_cost: float = Field(..., gt=0, description="Energy cost (€/kWh)")
    regulation_mode: Optional[str] = Field(default="", description="Regulation mode")
    initial_cost: Optional[float] = Field(default=0.0, ge=0, description="Initial investment cost (€)")


class DatabaseConfigSchema(BaseModel):
    """Schema for database configuration."""
    db_type: str = Field(default="sqlite", description="Database type (sqlite or access)")
    db_path: str = Field(..., description="Database file path")


class AdminConfigSchema(BaseModel):
    """Schema for admin configuration."""
    login: str = Field(..., description="Admin login")
    password_sha: str = Field(..., description="Admin password SHA-256 hash")
