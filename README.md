# Flutter Assignment Projects

This repository contains three Flutter projects, each with a FastAPI backend.

## Projects

1.  **Project 1: Business Card** (`project1_business_card`)
2.  **Project 2: Taskmaster** (`project2_taskmaster`)
3.  **Project 3: Weather** (`project3_weather`)

---

## How to Run

Each project consists of a **frontend** (Flutter) and a **backend** (FastAPI).

### 1. Prerequisites

-   **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
-   **Python 3.8+**: [Install Python](https://www.python.org/downloads/)
-   **Dependencies**:
    -   Python: `pip install fastapi uvicorn httpx`
    -   Flutter: `flutter pub get` (run inside each frontend directory)

### 2. Running the Backend

Navigate to the `backend` folder of the project you want to run:

```bash
cd projectX_name/backend
python main.py
# OR
uvicorn main:app --reload --port <PORT>
```

**Ports used by default:**
-   **Business Card**: `8000`
-   **Taskmaster**: `8001`
-   **Weather**: `8002`

### 3. Running the Frontend

Navigate to the `frontend` folder of the project:

```bash
cd projectX_name/frontend
flutter pub get
flutter run
```

---

## Project Details

### Project 1: Business Card
A simple business card app with a backend to serve profile data.
-   **Backend Port**: 8000
-   **Tech**: Flutter, FastAPI

### Project 2: Taskmaster
A task management app that persists tasks in a SQLite database via the FastAPI backend.
-   **Backend Port**: 8001
-   **Tech**: Flutter, FastAPI, SQLite

### Project 3: Weather
A weather application that fetches real-time data from Open-Meteo and Nominatim APIs via a proxy backend.
-   **Backend Port**: 8002
-   **Tech**: Flutter, FastAPI, external API integration
