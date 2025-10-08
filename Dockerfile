# ----------------------------
# Stage 1: Build
# ----------------------------
FROM node:22.20.0-alpine AS build

WORKDIR /usr/src/wpp-server

# Copy package files first (for better caching)
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Build the TypeScript project
RUN npm run build

# ----------------------------
# Stage 2: Runtime
# ----------------------------
FROM node:22.20.0-alpine

WORKDIR /usr/src/wpp-server

# Install Chromium for Puppeteer/WPPConnect
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Copy only built files and necessary modules from build stage
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./

# Install only production dependencies
RUN npm ci --only=production --legacy-peer-deps

# Expose server port
EXPOSE 21465

# Environment variables for Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    CHROME_PATH=/usr/bin/chromium-browser \
    NODE_ENV=production

# Start the server
CMD ["node", "dist/server.js"]
