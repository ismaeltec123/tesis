# INSTRUCCIONES DE CONFIGURACIÓN

Sigue estos pasos para configurar completamente el proyecto:

## 📝 PASO 1: Configurar Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita la **Google Calendar API**:
   - Ve a "APIs y servicios" > "Biblioteca"
   - Busca "Google Calendar API"
   - Haz clic en "Habilitar"

4. Crear credenciales OAuth 2.0:
   - Ve a "APIs y servicios" > "Credenciales"
   - Haz clic en "Crear credenciales" > "ID de cliente OAuth 2.0"
   - Tipo de aplicación: **Aplicación web**
   - Nombre: "Flutter Calendar Integration"
   - URI de redireccionamiento autorizados: `http://localhost:8000/api/auth/callback`
   - Haz clic en "Crear"

5. Descarga el archivo JSON y guárdalo como: `config/credentials.json`

## 🔥 PASO 2: Configurar Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto existente (el mismo de tu app Flutter)
3. Ve a "Configuración del proyecto" > "Cuentas de servicio"
4. Haz clic en "Generar nueva clave privada"
5. Descarga el archivo JSON y guárdalo como: `config/firebase-service-account.json`

## ⚙️ PASO 3: Configurar Variables de Entorno

1. Copia el archivo de ejemplo:
   ```
   copy .env.example .env
   ```

2. Abre el archivo `.env` y completa con tus datos:
   - `GOOGLE_CLIENT_ID`: Del archivo credentials.json (campo "client_id")
   - `GOOGLE_CLIENT_SECRET`: Del archivo credentials.json (campo "client_secret")

## 🚀 PASO 4: Iniciar el Servidor

```bash
python start_server.py
```

El servidor estará disponible en: http://localhost:8000

## 🔐 PASO 5: Autenticación Inicial

1. Ve a: http://localhost:8000/api/auth/google
2. Copia la URL de autorización que aparece
3. Ábrela en tu navegador
4. Autoriza la aplicación con tu cuenta de Google
5. Serás redirigido automáticamente y la autenticación se completará

## ✅ PASO 6: Verificar Funcionamiento

1. Ve a: http://localhost:8000/docs (Documentación de la API)
2. Prueba el endpoint: `/api/auth/status` (debe mostrar "authenticated": true)
3. Prueba el endpoint: `/api/sync/import-from-google` para importar eventos

## 📱 PASO 7: Integrar con Flutter

Una vez que el backend esté funcionando, agrega estas dependencias a tu `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
```

Y modifica tu `EventViewModel` para usar la API Python (ver README.md para detalles).

---

## 🆘 Solución de Problemas

### Error: "No module named 'fastapi'"
```bash
pip install -r requirements.txt
```

### Error: "credentials.json not found"
- Asegúrate de que el archivo está en `config/credentials.json`
- Verifica que descargaste el archivo correcto de Google Cloud Console

### Error: "firebase-service-account.json not found"
- Asegúrate de que el archivo está en `config/firebase-service-account.json`
- Verifica que descargaste el archivo de Firebase Console

### Error de CORS en Flutter
- El servidor ya está configurado para CORS
- Si usas un emulador, agrega la IP del emulador a `ALLOWED_ORIGINS` en `config/settings.py`
