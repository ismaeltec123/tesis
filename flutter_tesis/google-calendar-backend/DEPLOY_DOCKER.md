# 🚀 Docker Deployment on Render.com

This guide explains how to deploy the Google Calendar Backend to Render.com using Docker.

## 📋 Prerequisites

1. GitHub repository with the backend code
2. Google Cloud Console project with Calendar API enabled  
3. Render.com account

## 📁 Files for Docker Deployment

- `Dockerfile` - Docker configuration for containerized deployment
- `render.yaml` - Render service configuration (Docker mode)
- `requirements-render.txt` - Python dependencies (Pydantic v1 compatible)
- `.dockerignore` - Files to exclude from Docker build

## 🔧 Step 1: Prepare Repository

1. Ensure all files are committed to your GitHub repository
2. The backend should be in the path: `flutter_tesis/google-calendar-backend/`

## 🌐 Step 2: Create Render Service

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Configure the service:
   - **Name**: `google-calendar-backend`
   - **Root Directory**: `flutter_tesis/google-calendar-backend`
   - **Environment**: `Docker` ⚠️ **IMPORTANT: Select Docker, not Python**
   - **Plan**: Free

## ⚙️ Step 3: Configure Environment Variables

Set these environment variables in Render:

- `GOOGLE_CLIENT_ID`: Your Google OAuth Client ID
- `GOOGLE_CLIENT_SECRET`: Your Google OAuth Client Secret
- `BASE_URL`: `https://google-calendar-backend.onrender.com`
- `PORT`: `8001`
- `HOST`: `0.0.0.0`
- `DEBUG`: `false`

## 🚀 Step 4: Deploy

1. Click "Create Web Service"
2. Render will automatically build using the Dockerfile
3. Wait for the build to complete (5-10 minutes)
4. Your service will be available at: `https://google-calendar-backend.onrender.com`

## 🔑 Step 5: Update Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to APIs & Services → Credentials
3. Edit your OAuth 2.0 Client ID
4. Add to Authorized redirect URIs:
   ```
   https://google-calendar-backend.onrender.com/auth/callback
   ```

## 📱 Step 6: Update Flutter App

Update your Flutter app's API base URL to:
```dart
static const String baseUrl = 'https://google-calendar-backend.onrender.com';
```

## ✅ Testing the Deployment

1. Visit: `https://google-calendar-backend.onrender.com/docs`
2. Test the `/health` endpoint
3. Test the OAuth flow: `https://google-calendar-backend.onrender.com/auth`

## 🐳 Local Docker Testing

To test locally:

```bash
# Build the image
docker build -t google-calendar-backend .

# Run the container
docker run -p 8001:8001 --env-file .env google-calendar-backend
```

## 🔧 Troubleshooting

### Common Issues:

1. **Build fails**: Check Dockerfile and requirements-render.txt
2. **Service won't start**: Check environment variables
3. **OAuth errors**: Verify Google Cloud Console redirect URIs
4. **CORS errors**: Ensure CORS is configured properly

### Why Docker?

- ✅ No Rust compilation issues (unlike Python environment)
- ✅ Consistent environment across local and production
- ✅ Faster builds and deployments
- ✅ Better dependency management

### Environment Variable Checklist:

- ✅ `GOOGLE_CLIENT_ID` (from Google Cloud Console)
- ✅ `GOOGLE_CLIENT_SECRET` (from Google Cloud Console)  
- ✅ `BASE_URL` = https://google-calendar-backend.onrender.com
- ✅ `PORT` = 8001
- ✅ `HOST` = 0.0.0.0
- ✅ `DEBUG` = false

## 📋 Deployment Checklist

- [ ] All files committed to GitHub
- [ ] Service created with **Docker** environment (not Python)
- [ ] Root directory set to `flutter_tesis/google-calendar-backend`
- [ ] All environment variables configured
- [ ] Google Cloud Console redirect URI updated
- [ ] Flutter app base URL updated
- [ ] Service deployed and accessible
