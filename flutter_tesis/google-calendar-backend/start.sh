#!/bin/bash

echo "Iniciando Google Calendar Integration API..."
echo ""

# Verificar que Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "Error: Python3 no está instalado"
    exit 1
fi

# Verificar que las dependencias están instaladas
python3 -c "import fastapi" 2>/dev/null || {
    echo "Instalando dependencias..."
    pip3 install -r requirements.txt
}

# Verificar archivos de configuración
if [ ! -f "config/credentials.json" ]; then
    echo ""
    echo "¡IMPORTANTE! No se encontró config/credentials.json"
    echo "Copia tu archivo de credenciales de Google Cloud Console a:"
    echo "config/credentials.json"
    echo ""
    echo "Puedes usar config/credentials.json.example como referencia"
    echo ""
fi

if [ ! -f "config/firebase-service-account.json" ]; then
    echo ""
    echo "¡IMPORTANTE! No se encontró config/firebase-service-account.json"
    echo "Copia tu archivo de credenciales de Firebase a:"
    echo "config/firebase-service-account.json"
    echo ""
    echo "Puedes usar config/firebase-service-account.json.example como referencia"
    echo ""
fi

# Iniciar el servidor
echo "Iniciando servidor en http://localhost:8000"
echo "Documentación disponible en http://localhost:8000/docs"
echo ""
echo "Presiona Ctrl+C para detener el servidor"
echo ""

python3 -m app.main
