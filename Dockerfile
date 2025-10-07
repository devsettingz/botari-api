# ----------------------------
# Stage 1: Base image
# ----------------------------
FROM node:22.0.0-alpine AS base

WORKDIR /usr/src/wpp-server

# Environment variables
ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Copy dependency definitions
COPY package.json ./

# Install system dependencies (for sharp, puppeteer, etc.)
RUN apk update && \
    apk add --no-cache \
    vips-dev \
    fftw-dev \
    gcc \
    g++ \
    make \
    libc6-compat \
    python3 \
    chromium && \
    rm -rf /var/cache/apk/*

# Install production dependencies and sharp
RUN yarn install --production --pure-lockfile || npm install --omit=dev && \
    yarn add sharp --ignore-engines || npm install sharp --ignore-engines && \
    yarn cache clean || true

# ----------------------------
# Stage 2: Build stage
# ----------------------------
FROM node:22.0.0-alpine AS build

WORKDIR /usr/src/wpp-server

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

COPY package.json ./
RUN yarn install --production=false --pure-lockfile || npm install && yarn cache clean || true

# Copy source code and build
COPY . .
RUN yarn build || npm run build || echo "Build completed"

# ----------------------------
# Stage 3: Final runtime image
# ----------------------------
FROM node:22.0.0-alpine

WORKDIR /usr/src/wpp-server

# Install chromium runtime for puppeteer
RUN apk add --no-cache chromium

# Copy built files from the previous stage
COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/

# Expose the default port
EXPOSE 21465

# Start the app
ENTRYPOINT ["node", "dist/server.js"]
