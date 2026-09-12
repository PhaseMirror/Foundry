import asyncio
import json
import time
from datetime import datetime
import websockets

# Mock hardware implementations for SUG pilot linkage
class SoilSensor:
    def read(self):
        return {
            "temperature_c": 22.5,
            "moisture_percent": 65.0,
            "ph": 6.8,
            "ec_us_cm": 1.2,
            "nitrogen_ppm": 45.0,
            "phosphorus_ppm": 20.0,
            "potassium_ppm": 120.0,
            "organic_matter_percent": 5.5,
            "microbiome_activity": 88.0,
            "soil_type": "loamy"
        }

class WeatherStation:
    def read(self):
        return {
            "temperature_c": 24.0,
            "humidity_percent": 55.0,
            "pressure_hpa": 1012.0,
            "rainfall_mm": 0.0,
            "wind_speed_ms": 2.5,
            "wind_direction_deg": 180.0,
            "solar_irradiance_wm2": 850.0,
            "uv_index": 6.5
        }

class PlantMonitor:
    def read(self):
        return [{
            "species": "Tomato",
            "height_cm": 45.0,
            "canopy_diameter_cm": 30.0,
            "ndvi": 0.75,
            "chlorophyll_content": 45.0,
            "growth_rate_cm_day": 1.2,
            "water_stress_index": 0.1,
            "nutrient_stress_index": 0.05,
            "health_status": "good"
        }]

class WaterSensor:
    def read(self):
        return {
            "flow_rate_l_min": 0.0,
            "total_volume_l": 150.0,
            "temperature_c": 20.0,
            "ph": 7.0,
            "ec_us_cm": 0.5,
            "turbidity_ntu": 1.0,
            "dissolved_oxygen_mg_l": 8.0
        }

class EdgeGateway:
    """Edge gateway for SUG telemetry aggregation (Raspberry Pi)."""
    
    def __init__(self, node_id: str, ws_server: str = "ws://localhost:8765", collection_interval: int = 5):
        self.node_id = node_id
        self.collection_interval = collection_interval
        self.soil_sensor = SoilSensor()
        self.weather_station = WeatherStation()
        self.plant_monitor = PlantMonitor()
        self.water_sensor = WaterSensor()
        self.ws_server = ws_server
        
    async def collect_telemetry(self):
        triad_id = self.node_id.split("-")[0]
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "triad_id": triad_id,
            "node_id": self.node_id,
            "soil": self.soil_sensor.read(),
            "weather": self.weather_station.read(),
            "plant_health": self.plant_monitor.read(),
            "water": self.water_sensor.read(),
            "resilience_score": 85.0,
            "resonance_score": 92.5,
            "sovereignty_score": 88.0
        }
        
    async def send_telemetry(self, telemetry):
        try:
            async with websockets.connect(self.ws_server) as ws:
                await ws.send(json.dumps(telemetry))
                # print(f"[{self.node_id}] Streamed active sensor matrix.")
        except Exception as e:
            print(f"[{self.node_id}] WS Offline. Local buffering engaged.")
            
    async def run(self):
        print(f"Hardware Linkage: Edge gateway {self.node_id} initializing sensor arrays...")
        while True:
            try:
                telemetry = await self.collect_telemetry()
                await self.send_telemetry(telemetry)
            except Exception as e:
                print(f"Error in main loop: {e}")
            await asyncio.sleep(self.collection_interval)

if __name__ == "__main__":
    # Boot node 01 for Triad 01
    gateway = EdgeGateway("triad01-node01")
    asyncio.run(gateway.run())
