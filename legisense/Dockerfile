# Multi-stage Dockerfile for Legisense Frontend (Flutter)
# Stage 1: Build stage
FROM ubuntu:22.04 as builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.22.0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME
RUN flutter config --no-analytics
RUN flutter doctor

# Set work directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get Flutter dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build Flutter web app
RUN flutter build web --release --web-renderer html

# Stage 2: Production stage with Nginx
FROM nginx:alpine as production

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built Flutter app from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create non-root user
RUN addgroup -g 1001 -S legisense && \
    adduser -S legisense -u 1001

# Set proper permissions
RUN chown -R legisense:legisense /usr/share/nginx/html && \
    chown -R legisense:legisense /var/cache/nginx && \
    chown -R legisense:legisense /var/log/nginx && \
    chown -R legisense:legisense /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R legisense:legisense /var/run/nginx.pid

# Switch to non-root user
USER legisense

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
