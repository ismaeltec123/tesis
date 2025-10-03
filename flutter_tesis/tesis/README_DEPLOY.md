# Flutter Web Deployment to Render

This directory contains the Flutter web application for the calendar project.

## Build Process

The Flutter app is built using:
```bash
flutter build web
```

## Deployment

This is deployed as a static site on Render.com pointing to the `build/web` directory.

## API Integration

The app connects to the backend API at:
- Production: `https://tesis-calendario.onrender.com/api`
- Local: `http://localhost:8001/api`
