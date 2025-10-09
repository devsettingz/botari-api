# ----------------------------
# Stage 1: Build
# ----------------------------
FROM node:22.10.0-alpine AS build

WORKDIR /usr/src/wpp-server

# Copy package files first (for better caching)
COPY package*.json ./

# Install all dependencies (including devDependencies)
RUN npm install --force --legacy-peer-deps

# Copy the rest of your source code
COPY . .

# Ensure jsonwebtoken and types are installed
RUN npm install jsonwebtoken @types/jsonwebtoken --save --legacy-peer-deps

# Build the TypeScript project (creates dist/)
RUN npm run build || npx tsc

# ----------------------------
# Stage 2: Runtime
# ----------------------------
FROM node:22.10.0-alpine

WORKDIR /usr/src/wpp-server

# Install Chromium for Puppeteer/WPPConnect
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Copy compiled output and package files
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./

# Install only production dependencies
RUN npm install --omit=dev --legacy-peer-deps

# Expose the server port
EXPOSE 21465

# Puppeteer environment
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    CHROME_PATH=/usr/bin/chromium-browser \
    NODE_ENV=production

# Start the server
CMD ["node", "dist/server.js"]
