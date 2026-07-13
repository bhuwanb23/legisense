# Multi-stage build for Flutter web app
FROM ubuntu:22.04 as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_VERSION=3.24.0 \
    FLUTTER_HOME=/opt/flutter \
    PATH=$PATH:/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    lib32stdc++6 \
    lib32z1 \
    libstdc++6 \
    libgconf-2-4 \
    libxss1 \
    libasound2 \
    libxtst6 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    ${FLUTTER_HOME}/bin/flutter doctor

# Set up Flutter for web
RUN ${FLUTTER_HOME}/bin/flutter config --enable-web && \
    ${FLUTTER_HOME}/bin/flutter precache --web

# Build stage
FROM base as build

# Configurable backend API base URL (defaults to the deployed Render instance)
ARG LEGISENSE_API_BASE=https://legisense-1.onrender.com

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN ${FLUTTER_HOME}/bin/flutter pub get

# Copy source code
COPY . .

# Build for web
RUN ${FLUTTER_HOME}/bin/flutter build web --release --web-renderer html --dart-define=LEGISENSE_API_BASE=$LEGISENSE_API_BASE

# Production stage
FROM nginx:alpine as production

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set permissions (nginx user/group already exist in nginx:alpine)
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
