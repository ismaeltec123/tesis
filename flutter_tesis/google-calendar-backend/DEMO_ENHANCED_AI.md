# 🚀 DEMO ENHANCED AI - INSTRUCCIONES DE USO

## 📦 INSTALACIÓN DE DEPENDENCIAS

### 1. Backend Python
```bash
cd google-calendar-backend
pip install -r requirements-ml.txt
```

### 2. Configurar Groq API Key (OPCIONAL)
```bash
# Crear cuenta gratuita en https://console.groq.com/
# Obtener API key y agregarla al .env:
echo "GROQ_API_KEY=tu_groq_api_key_aquí" >> .env
```

**NOTA**: Si no tienes Groq API key, el sistema funcionará con **respuestas simuladas** para la demo.

## 🎯 INICIAR DEMO

### 1. Iniciar Backend Enhanced AI
```bash
cd google-calendar-backend
python -c "from app.main import app; import uvicorn; uvicorn.run(app, host='localhost', port=8004)"
```

### 2. Verificar que funciona
Abre: http://localhost:8004/docs
Deberías ver los endpoints `/api/enhanced-ai/`

### 3. Iniciar Flutter
```bash
cd tesis
flutter run
```

## 🎮 USAR LA DEMO

### 1. **Abrir Enhanced AI**
- En tu app Flutter, busca el nuevo botón **🧠 "Enhanced AI"** 
- Se abrirá el diálogo con 4 pestañas

### 2. **Pestaña "Análisis" 📊**
- Muestra insights ML de tu calendario
- Interpretación IA de patrones
- Métricas de productividad

### 3. **Pestaña "Chat IA" 💬**
- Chat conversacional con IA
- Prueba: "¿Cómo está mi calendario?"
- Prueba: "Organiza mi semana"
- Incluye contexto ML automáticamente

### 4. **Pestaña "Generar" ✨**
- Escribe: "matemáticas"
- IA genera evento completo con ML + Groq
- Título, descripción, duración, preparativos

### 5. **Pestaña "Estudiar" 📚**
- Materia: "Cálculo"
- Fecha examen: "2024-12-15"
- IA crea plan optimizado con ML

## 🤖 LO QUE VERÁS EN LA DEMO

### **Con Groq API Key:**
- ✅ Respuestas reales de Llama 3.1
- ✅ Análisis conversacional inteligente
- ✅ Generación de contenido avanzada
- ✅ Planes de estudio personalizados

### **Sin Groq API Key (Simulación):**
- ✅ ML funciona completamente
- ✅ Análisis de patrones reales
- ✅ Respuestas simuladas inteligentes
- ✅ Demo completa funcional

## 📊 FUNCIONALIDADES DE ML

### **Análisis que hace el ML:**
1. **Patrones de productividad** por horario
2. **Clasificación automática** de eventos
3. **Predicción de duración** óptima
4. **Clustering de horarios** del usuario
5. **Detección de sobrecarga** y problemas

### **Métricas ML:**
- Productividad promedio por hora
- Mejor día/hora para estudiar
- Distribución de actividades
- Balance vida-estudio-ejercicio

## 🎯 ENDPOINTS DE LA DEMO

```
POST /api/enhanced-ai/initialize          # Inicializar ML+IA
POST /api/enhanced-ai/analyze-calendar    # Análisis completo
POST /api/enhanced-ai/chat               # Chat inteligente  
POST /api/enhanced-ai/generate-event     # Generar evento
POST /api/enhanced-ai/create-study-plan  # Plan de estudio
GET  /api/enhanced-ai/predict-optimization # Predicciones ML
POST /api/enhanced-ai/demo-data          # Crear datos demo
```

## 🔧 TROUBLESHOOTING

### **Error: "Enhanced AI no disponible"**
```bash
# Verificar que el servidor está corriendo en puerto 8004
curl http://localhost:8004/api/enhanced-ai/system-status
```

### **Error: "Groq not available"**
- Funciona con simulación
- Para IA real: configurar GROQ_API_KEY en .env

### **Error: "sklearn not found"**
```bash
pip install scikit-learn numpy pandas joblib
```

### **Pocos datos para ML**
- Usa el botón "Crear datos demo" en la app
- O endpoint: POST /api/enhanced-ai/demo-data

## 🎉 DEMO COMPLETA

La demo muestra:

1. **🧠 Machine Learning real** analizando patrones
2. **🤖 IA conversacional** (Groq o simulada) 
3. **📊 Visualización** de insights ML
4. **✨ Generación inteligente** de contenido
5. **🎯 Optimización** basada en datos
6. **💬 Chat natural** con contexto
7. **📚 Planificación automática** de estudio

¡Tu proyecto ahora tiene IA de verdad! 🚀