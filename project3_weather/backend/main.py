from fastapi import FastAPI, HTTPException, Query
import httpx
import os

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="WeatherProxy API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MOCK_WEATHER = {
    "name": "Bengaluru",
    "sys": {"country": "IN"},
    "main": {"temp": 300.15, "feels_like": 302.15, "humidity": 60},
    "wind": {"speed": 5.5},
    "weather": [{"description": "clear sky", "icon": "01d", "main": "Clear"}],
    "coord": {"lat": 12.9716, "lon": 77.5946}
}

MOCK_AQI = {
    "list": [{
        "main": {"aqi": 2},
        "components": {"pm2_5": 12.5, "pm10": 25.0, "o3": 40.0}
    }]
}

# Open-Meteo WMO Code to Description/Icon mapping
WMO_CODES = {
    0: ("Clear sky", "01d", "Clear"),
    1: ("Mainly clear", "02d", "Clouds"),
    2: ("Partly cloudy", "03d", "Clouds"),
    3: ("Overcast", "04d", "Clouds"),
    45: ("Fog", "50d", "Fog"),
    48: ("Depositing rime fog", "50d", "Fog"),
    51: ("Drizzle: Light", "09d", "Drizzle"),
    53: ("Drizzle: Moderate", "09d", "Drizzle"),
    55: ("Drizzle: Dense", "09d", "Drizzle"),
    61: ("Rain: Slight", "10d", "Rain"),
    63: ("Rain: Moderate", "10d", "Rain"),
    65: ("Rain: Heavy", "10d", "Rain"),
    71: ("Snow fall: Slight", "13d", "Snow"),
    73: ("Snow fall: Moderate", "13d", "Snow"),
    75: ("Snow fall: Heavy", "13d", "Snow"),
    95: ("Thunderstorm: Slight or moderate", "11d", "Thunderstorm"),
}

def get_weather_info(code: int):
    return WMO_CODES.get(code, ("Unknown", "01d", "Clear"))

@app.get("/api/v1/weather")
async def get_weather(city: str = Query(...)):
    # 1. Geocode city name to coordinates using Nominatim
    geo_url = f"https://nominatim.openstreetmap.org/search?q={city}&format=json&limit=1"
    headers = {"User-Agent": "WeatherProxyApp/1.0"}
    
    async with httpx.AsyncClient() as client:
        try:
            geo_resp = await client.get(geo_url, headers=headers)
            if geo_resp.status_code != 200 or not geo_resp.json():
                raise HTTPException(status_code=404, detail=f"City '{city}' not found")
            
            location = geo_resp.json()[0]
            lat = float(location["lat"])
            lon = float(location["lon"])
            display_name = location["display_name"].split(",")[0]
            country_code = location.get("address", {}).get("country_code", "??").upper()
            
            # 2. Get weather from Open-Meteo
            weather_url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&timezone=auto"
            weather_resp = await client.get(weather_url)
            if weather_resp.status_code != 200:
                raise HTTPException(status_code=500, detail="Weather service error")
            
            data = weather_resp.json()["current"]
            desc, icon, main_cond = get_weather_info(data["weather_code"])
            
            return {
                "name": display_name,
                "sys": {"country": country_code},
                "main": {
                    "temp": data["temperature_2m"] + 273.15, # Convert to Kelvin for frontend compatibility
                    "feels_like": data["apparent_temperature"] + 273.15,
                    "humidity": data["relative_humidity_2m"]
                },
                "wind": {"speed": data["wind_speed_10m"] / 3.6}, # km/h to m/s
                "weather": [{"description": desc, "icon": icon, "main": main_cond}],
                "coord": {"lat": lat, "lon": lon}
            }
        except HTTPException as e:
            raise e
        except Exception as e:
            return {**MOCK_WEATHER, "name": city}

@app.get("/api/v1/weather/coords")
async def get_weather_coords(lat: float, lon: float):
    headers = {"User-Agent": "WeatherProxyApp/1.0"}
    async with httpx.AsyncClient() as client:
        try:
            # 1. Reverse geocode to get city name
            rev_url = f"https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lon}&format=json"
            rev_resp = await client.get(rev_url, headers=headers)
            city_name = "Unknown"
            country_code = "??"
            if rev_resp.status_code == 200:
                rev_data = rev_resp.json()
                city_name = rev_data.get("address", {}).get("city", rev_data.get("address", {}).get("town", "Unknown"))
                country_code = rev_data.get("address", {}).get("country_code", "??").upper()

            # 2. Get weather from Open-Meteo
            weather_url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&timezone=auto"
            weather_resp = await client.get(weather_url)
            if weather_resp.status_code != 200:
                raise HTTPException(status_code=500, detail="Weather service error")
            
            data = weather_resp.json()["current"]
            desc, icon, main_cond = get_weather_info(data["weather_code"])
            
            return {
                "name": city_name,
                "sys": {"country": country_code},
                "main": {
                    "temp": data["temperature_2m"] + 273.15,
                    "feels_like": data["apparent_temperature"] + 273.15,
                    "humidity": data["relative_humidity_2m"]
                },
                "wind": {"speed": data["wind_speed_10m"] / 3.6},
                "weather": [{"description": desc, "icon": icon, "main": main_cond}],
                "coord": {"lat": lat, "lon": lon}
            }
        except Exception:
            return {**MOCK_WEATHER, "coord": {"lat": lat, "lon": lon}}

@app.get("/api/v1/air_pollution")
async def get_air_pollution(lat: float, lon: float):
    # Open-Meteo Air Quality API
    url = f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=pm2_5,pm10,ozone,us_aqi"
    async with httpx.AsyncClient() as client:
        try:
            r = await client.get(url)
            if r.status_code == 200:
                data = r.json()["current"]
                # Map to format expected by frontend
                return {
                    "list": [{
                        "main": {"aqi": data.get("us_aqi_index", data.get("us_aqi", 1) // 50 + 1)}, # Rough conversion if us_aqi_index missing
                        "components": {
                            "pm2_5": data["pm2_5"],
                            "pm10": data["pm10"],
                            "o3": data["ozone"]
                        }
                    }]
                }
        except Exception:
            pass
        return MOCK_AQI

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
