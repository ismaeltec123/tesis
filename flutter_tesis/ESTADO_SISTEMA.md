# ESTADO DEL SISTEMA - RESUMEN COMPLETO
# =====================================

## ✅ SERVICIOS ACTIVOS

1. **Backend** (puerto 8001)
   - Archivo: `google-calendar-backend/simple_server.py`
   - Estado: ✅ CORRIENDO
   - Endpoints:
     * GET  /api/calendar/events
     * POST /api/calendar/sync-schedules  (ARREGLADO - calcula fechas por día)
     * DELETE /api/admin/dangerous/delete-all-events

2. **OCR Service** (puerto 8002)
   - Archivo: `docker/app.py`
   - Estado: ✅ CORRIENDO  
   - Endpoint: POST /process-image

3. **Flutter App** (Chrome)
   - Archivo: `tesis/lib/main.dart`
   - Estado: ✅ CORRIENDO
   - Vista profesor: http://localhost:62886

4. **Admin Panel** (puerto 5173)
   - Archivo: `admin-panel/src/App.tsx`
   - Estado: ✅ RESTAURADO
   - Iniciar: `cd admin-panel && npm run dev`

## 🐛 PROBLEMA PRINCIPAL

**FECHAS INCORRECTAS EN EVENTOS EXPORTADOS**

- **Síntoma**: Todos los eventos aparecen en lunes, independientemente del día real
- **Causa**: Endpoint `/sync-schedules` no calcula correctamente las fechas
- **Evidencia**: 
  ```json
  {
    "description": "Día: Martes",
    "date": "2025-11-17T09:00:00-05:00"  // ← 17 nov es LUNES, no martes
  }
  ```

- **Fix aplicado** (líneas 741-809 de calendar_routes.py):
  ```python
  # Calcular próximo lunes
  start_monday = today + timedelta(days=days_until_monday)
  
  # Para cada semana (0-3)
  for week_num in range(4):
      # Calcular fecha correcta
      days_offset = (week_num * 7) + target_weekday  # ← CLAVE
      event_date = start_monday + timedelta(days=days_offset)
  ```

- **Estado**: ⚠️ CÓDIGO ARREGLADO PERO NO PROBADO
  - Backend necesita reiniciarse
  - Logs de debug agregados para verificar cálculo

## 📋 PASOS PARA PROBAR EL FIX

1. **Abrir Admin Panel**: 
   ```bash
   cd admin-panel
   npm run dev
   # Abrir http://localhost:5173
   ```

2. **Borrar todos los eventos**:
   - Click en botón rojo "BORRAR TODOS LOS EVENTOS"

3. **Reiniciar backend** (para cargar código nuevo):
   ```bash
   # Detener el proceso Python actual
   cd google-calendar-backend
   python simple_server.py
   ```

4. **Exportar desde Flutter**:
   - Vista Profesor → "Exportar al calendario"

5. **Verificar logs del backend**:
   Deberías ver algo como:
   ```
   🔍 Debug: week_num=0, target_weekday=1 (Mar), days_offset=1
   🔍 start_monday=2025-11-17 (Monday), event_date=2025-11-18 (Tuesday)
   
   🔍 Debug: week_num=0, target_weekday=2 (Mié), days_offset=2  
   🔍 start_monday=2025-11-17 (Monday), event_date=2025-11-19 (Wednesday)
   ```

6. **Verificar en Google Calendar**:
   - Eventos de Martes deben estar el 18, 25 nov, etc.
   - Eventos de Miércoles deben estar el 19, 26 nov, etc.
   - Eventos de Lunes deben estar el 17, 24 nov, etc.

## 📁 ARCHIVOS CLAVE MODIFICADOS HOY

1. **calendar_routes.py** (líneas 741-866)
   - Endpoint `sync-schedules` completamente reescrito
   - Calcula 4 semanas de eventos
   - Alterna par/impar correctamente
   - Logs de debug agregados

2. **teacher_schedule_service.dart** (líneas 313-348)
   - Método `exportToCalendar()` implementado
   - Envía POST a `/api/calendar/sync-schedules`
   - Incluye: day_of_week, week_type, times, classroom

3. **teacher_schedule_view.dart** (líneas 764-810)
   - Diálogo de exportación arreglado
   - Contextos corregidos para evitar loop infinito

4. **schedule_parser_routes.py**
   - Restaurado (estaba vacío)
   - Endpoint `/parse-schedule` para OCR

5. **Admin Panel** (todos los archivos)
   - Restaurados completamente
   - App.tsx, index.html, package.json, tsconfig.json

## 🔧 COMANDOS RÁPIDOS

**Iniciar todo de una vez**:
```bash
START_ALL_SERVICES.bat
```

**Reiniciar solo el backend**:
```bash
cd google-calendar-backend
python simple_server.py
```

**Ver logs en tiempo real**:
- Backend: Terminal python que ejecuta `simple_server.py`
- Flutter: Terminal donde ejecutaste `flutter run`

**Verificar eventos**:
```powershell
cd google-calendar-backend
Get-Content temp_events.json | ConvertFrom-Json | Select-Object title,date,description -First 5
```

## 🎯 PRÓXIMOS PASOS

1. Reiniciar backend
2. Probar exportación
3. Verificar logs muestran días correctos
4. Confirmar en Google Calendar

**Si los logs muestran fechas correctas pero Google Calendar sigue mal**:
- Problema está en `calendar_service.py` (creación del evento)
- Revisar timezone America/Mexico_City

**Si los logs muestran fechas incorrectas**:
- Problema en cálculo `days_offset`
- Verificar `target_weekday` (0=Lun, 1=Mar, 2=Mié)
