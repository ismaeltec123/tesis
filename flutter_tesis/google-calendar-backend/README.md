# Google Calendar + Firebase Integration API

Este proyecto proporciona una API REST que actúa como puente entre tu aplicación Flutter/Firebase y Google Calendar, permitiendo sincronización bidireccional de eventos.

## 🚀 Características

- **Sincronización Bidireccional**: Eventos creados en Flutter se sincronizan automáticamente con Google Calendar y viceversa
- **Autenticación OAuth2**: Integración segura con Google Calendar API
- **API REST**: Endpoints fáciles de consumir desde Flutter
- **Firebase Integration**: Mantiene compatibilidad con tu base de datos Firebase actual

## 📋 Requisitos Previos

1. **Python 3.8+**
2. **Proyecto en Google Cloud Console**
3. **Firebase Project configurado**
4. **Credenciales de Google Calendar API**

## ⚙️ Configuración

### 1. Configurar Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita la **Google Calendar API**
4. Ve a **Credenciales** > **Crear credenciales** > **ID de cliente OAuth 2.0**
5. Configura:
   - Tipo de aplicación: **Aplicación web**
   - URI de redireccionamiento autorizado: `http://localhost:8001/auth/callback`
6. Descarga el archivo JSON de credenciales

### 2. Configurar el Proyecto

```bash
# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales
```

### 3. Agregar Credenciales

1. Coloca el archivo de credenciales de Google en: `config/credentials.json`
2. Agrega tu archivo de servicio de Firebase en: `config/firebase-service-account.json`
3. Actualiza el archivo `.env` con tus datos

## 🚀 Uso

### Iniciar el Servidor

```bash
# Desde la raíz del proyecto
python -m app.main

# O usando uvicorn directamente
uvicorn app.main:app --host localhost --port 8001 --reload
```

### API Endpoints

#### 🔐 Autenticación
```
GET  /api/auth/google          # Obtener URL de autorización
GET  /api/auth/callback        # Callback de autorización
GET  /api/auth/status          # Estado de autenticación
POST /api/auth/revoke          # Revocar autenticación
```

#### 📅 Gestión de Eventos
```
POST /api/calendar/events      # Crear evento (sincroniza con Google)
GET  /api/calendar/events      # Obtener todos los eventos
PUT  /api/calendar/events/{id} # Actualizar evento
DELETE /api/calendar/events/{id} # Eliminar evento
```

#### 🔄 Sincronización
```
POST /api/sync/import-from-google  # Importar eventos de Google Calendar
POST /api/sync/sync-to-google      # Sincronizar eventos a Google Calendar
POST /api/sync/full-sync           # Sincronización completa bidireccional
```

## 📱 Integración con Flutter

Para integrar con tu aplicación Flutter, agrega estos cambios:

### 1. Agregar Dependencias en pubspec.yaml
```yaml
dependencies:
  http: ^1.1.0
```

### 2. Crear Servicio de API
```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://localhost:8001/api';
  
  static Future<void> syncWithGoogle() async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/full-sync'),
    );
    // Manejar respuesta
  }
  
  static Future<void> createEvent(EventModel event) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calendar/events'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(event.toMap()),
    );
    // Manejar respuesta
  }
}
```

### 3. Modificar EventViewModel
```dart
// En tu EventViewModel existente
class EventViewModel extends ChangeNotifier {
  
  Future<void> loadEvents() async {
    // Primero sincronizar con Google Calendar
    await ApiService.syncWithGoogle();
    
    // Luego cargar eventos de Firebase (código existente)
    // ...
  }
  
  Future<void> addEvent(EventModel event) async {
    try {
      // Crear evento a través de la API (sincroniza automáticamente)
      await ApiService.createEvent(event);
      
      // Recargar eventos
      await loadEvents();
      notifyListeners();
    } catch (e) {
      // Manejar error
    }
  }
}
```

## 🔧 Estructura del Proyecto

```
google-calendar-backend/
├── app/
│   ├── main.py                    # Punto de entrada FastAPI
│   ├── auth/
│   │   └── google_oauth.py        # Autenticación Google OAuth2
│   ├── services/
│   │   ├── calendar_service.py    # Servicio Google Calendar
│   │   └── firebase_sync.py       # Sincronización Firebase
│   ├── models/
│   │   └── event_models.py        # Modelos Pydantic
│   └── routes/
│       ├── auth_routes.py         # Rutas de autenticación
│       ├── calendar_routes.py     # Rutas de calendario
│       └── sync_routes.py         # Rutas de sincronización
├── config/
│   ├── settings.py                # Configuración
│   ├── credentials.json           # Credenciales Google (agregar)
│   └── firebase-service-account.json # Credenciales Firebase (agregar)
└── tokens/                        # Tokens de acceso (generado automáticamente)
```

## 🔄 Flujo de Funcionamiento

1. **Usuario abre la app Flutter** → Se ejecuta sincronización automática
2. **API Python** → Obtiene eventos de Google Calendar
3. **API** → Guarda/actualiza eventos en Firebase
4. **Usuario crea evento en Flutter** → Se envía a la API Python
5. **API** → Crea evento en Google Calendar Y en Firebase
6. **Sincronización completa** entre ambas plataformas

## 📚 Documentación de la API

Una vez que el servidor esté corriendo, puedes ver la documentación interactiva en:

- **Swagger UI**: http://localhost:8001/docs
- **ReDoc**: http://localhost:8001/redoc

## 🔒 Seguridad

- Las credenciales se almacenan localmente y no se comparten
- Los tokens de acceso se refrescan automáticamente
- CORS configurado para desarrollo local
- Variables de entorno para configuración sensible

## 🛠️ Troubleshooting

### Error: "Import could not be resolved"
```bash
# Instalar dependencias
pip install -r requirements.txt

# O instalar individualmente
pip install fastapi uvicorn google-api-python-client firebase-admin
```

### Error de autenticación Google
1. Verificar que las credenciales están en `config/credentials.json`
2. Verificar que la URI de redirección coincide en Google Cloud Console
3. Verificar que Google Calendar API está habilitada

### Error de Firebase
1. Verificar que el archivo de servicio está en `config/firebase-service-account.json`
2. Verificar permisos del archivo de servicio
3. Verificar que el proyecto Firebase es correcto

## 📞 Soporte

Si encuentras algún problema:
1. Revisa los logs en la consola del servidor
2. Verifica la configuración en `.env`
3. Asegúrate de que todos los archivos de credenciales están en su lugar
