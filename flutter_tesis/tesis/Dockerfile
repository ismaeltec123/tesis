# Multi-stage build for Flutter Web
FROM cirrusci/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.* ./

# Get Flutter dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build Flutter web app
RUN flutter build web

# Production stage with nginx
FROM nginx:alpine

# Copy built app to nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
