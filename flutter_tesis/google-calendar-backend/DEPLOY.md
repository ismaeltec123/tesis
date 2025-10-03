# 🚀 Despliegue en Render

Esta guía te ayudará a desplegar el backend de Google Calendar en Render.

## 📋 Prerrequisitos

1. **Cuenta en Render:** https://render.com
2. **Repositorio en GitHub** con el código del backend
3. **Credenciales de Google Cloud Console**

## 🛠️ Pasos para el despliegue

### 1. Preparar el repositorio
```bash
git add .
git commit -m "Preparar backend para despliegue en Render"
git push origin main
```

### 2. Crear servicio en Render
1. Ve a https://dashboard.render.com
2. Haz clic en "New +" → "Web Service"
3. Conecta tu repositorio de GitHub
4. Selecciona la carpeta `google-calendar-backend`

### 3. Configuración del servicio
- **Name:** `google-calendar-backend`
- **Environment:** `Python 3`
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `python simple_server.py`

### 4. Variables de entorno
Configura estas variables en Render:

```
GOOGLE_CLIENT_ID=tu_client_id_de_google_cloud
GOOGLE_CLIENT_SECRET=tu_client_secret_de_google_cloud
DEBUG=False
```

### 5. Actualizar Google Cloud Console
Una vez desplegado, actualiza las URIs autorizadas en Google Cloud Console:
- Ve a APIs & Services → Credentials
- Edita tu aplicación OAuth 2.0
- Agrega: `https://tu-app.onrender.com/api/auth/callback`

### 6. Actualizar Flutter
Cambia la URL del backend en Flutter:
```dart
static const String baseUrl = 'https://tu-app.onrender.com/api';
```

## 🔍 URLs importantes
- **API:** `https://tu-app.onrender.com`
- **Documentación:** `https://tu-app.onrender.com/docs`
- **Health Check:** `https://tu-app.onrender.com/health`

## ⚠️ Notas importantes
- Render puede tomar 1-2 minutos en arrancar (tier gratuito)
- Los logs están disponibles en el dashboard de Render
- El servicio se duerme después de 15 minutos de inactividad
