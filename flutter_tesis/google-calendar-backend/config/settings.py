import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Google OAuth2 Settings
    GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
    GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")
    
    # Determinar entorno y configurar redirect URI
    IS_PRODUCTION = os.getenv("RENDER") is not None
    BASE_URL = os.getenv("RENDER_EXTERNAL_URL", "http://localhost:8001")
    GOOGLE_REDIRECT_URI = os.getenv("GOOGLE_REDIRECT_URI", f"{BASE_URL}/api/auth/callback")
    GOOGLE_SCOPES = [
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/calendar.events"
    ]
    
    # Firebase Settings
    FIREBASE_SERVICE_ACCOUNT_PATH = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "./config/firebase-service-account.json")
    
    # API Settings
    API_HOST = os.getenv("API_HOST", "localhost")
    API_PORT = int(os.getenv("API_PORT", 8001))
    DEBUG = os.getenv("DEBUG", "True").lower() == "true"
    
    # CORS Settings
    ALLOWED_ORIGINS = [
        "*",  # Permitir todos los orígenes en desarrollo
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:8081",
        "http://localhost:9000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8081",
        "http://127.0.0.1:9000",
        "null",  # Para pruebas locales
    ]

settings = Settings()
