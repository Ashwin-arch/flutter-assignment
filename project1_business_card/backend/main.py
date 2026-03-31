from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(title="Digital Business Card API")

class ContactItem(BaseModel):
    icon_name: str
    label: str
    value: str
    url: Optional[str] = None

class Profile(BaseModel):
    name: str
    role: str
    location: str
    about_me: str
    contacts: List[ContactItem]
    skills: List[dict]

@app.get("/api/v1/profile", response_model=Profile)
async def get_profile():
    return {
        "name": "Argos Dev",
        "role": "Flutter Developer · Karnataka",
        "location": "Bengaluru, Karnataka",
        "about_me": "I'm a passionate Flutter developer based in Karnataka, building civic tech and tourism apps. I love crafting immersive dark-themed UIs with rich animations and meaningful interactions. Currently working on CivicPulse and Incredible Karnataka.",
        "contacts": [
            {"icon_name": "phone_rounded", "label": "Phone", "value": "+91 98765 43210", "url": "tel:+919876543210"},
            {"icon_name": "email_rounded", "label": "Email", "value": "argos@example.com", "url": "mailto:argos@example.com"},
            {"icon_name": "code_rounded", "label": "GitHub", "value": "github.com/argos-dev", "url": "https://github.com/argos-dev"},
            {"icon_name": "location_on_rounded", "label": "Location", "value": "Bengaluru, Karnataka", "url": None},
        ],
        "skills": [
            {"label": "Flutter", "icon_name": "flutter_dash", "color": 0xFF54C5F8},
            {"label": "Dart", "icon_name": "code", "color": 0xFF00B4D8},
            {"label": "Firebase", "icon_name": "local_fire_department", "color": 0xFFFF9800},
            {"label": "FastAPI", "icon_name": "bolt", "color": 0xFF4CAF50},
            {"label": "React", "icon_name": "hub_rounded", "color": 0xFF61DAFB},
            {"label": "UI/UX", "icon_name": "palette_rounded", "color": 0xFFE040FB},
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
