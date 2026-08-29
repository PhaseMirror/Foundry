from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional
from enum import Enum

class SoilType(Enum):
    SANDY = "sandy"
    LOAMY = "loamy"
    CLAYEY = "clayey"
    SILTY = "silty"

class PlantHealth(Enum):
    EXCELLENT = "excellent"
    GOOD = "good"
    FAIR = "fair"
    POOR = "poor"
    CRITICAL = "critical"

@dataclass
class SoilTelemetry:
    timestamp: datetime
    node_id: str
    temperature_c: float
    moisture_percent: float
    ph: float
    ec_us_cm: float
    nitrogen_ppm: float
    phosphorus_ppm: float
    potassium_ppm: float
    organic_matter_percent: float
    microbiome_activity: float
    soil_type: SoilType

@dataclass
class WeatherTelemetry:
    timestamp: datetime
    node_id: str
    temperature_c: float
    humidity_percent: float
    pressure_hpa: float
    rainfall_mm: float
    wind_speed_ms: float
    wind_direction_deg: float
    solar_irradiance_wm2: float
    uv_index: float

@dataclass
class PlantHealthTelemetry:
    timestamp: datetime
    node_id: str
    species: str
    height_cm: float
    canopy_diameter_cm: float
    ndvi: float
    chlorophyll_content: float
    growth_rate_cm_day: float
    water_stress_index: float
    nutrient_stress_index: float
    health_status: PlantHealth

@dataclass
class WaterTelemetry:
    timestamp: datetime
    node_id: str
    flow_rate_l_min: float
    total_volume_l: float
    temperature_c: float
    ph: float
    ec_us_cm: float
    turbidity_ntu: float
    dissolved_oxygen_mg_l: float

@dataclass
class AggregateTelemetry:
    timestamp: datetime
    triad_id: str
    soil: SoilTelemetry
    weather: WeatherTelemetry
    plant_health: List[PlantHealthTelemetry]
    water: WaterTelemetry
    resilience_score: float
    resonance_score: float
    sovereignty_score: float
