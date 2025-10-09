# ----------------------------
# Stage 1: Build
# ----------------------------
FROM node:22.10.0-alpine AS build
# Use a slightly more stable Alpine build; Render supports this better

WORKDIR /usr/src/wpp-server

# Copy package files first (for caching)
COPY package*.json ./

# Install dependencies (include dev deps for build)
RUN npm install --force

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# ----------------------------
# Stage 2: Runtime
# ----------------------------
FROM node:22.10.0-alpine

WORKDIR /usr/src/wpp-server

# Install Chromium and required fonts/libs for Puppeteer or WPPConnect
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Copy compiled dist and minimal files from build stage
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./

# Install only production dependencies
RUN npm install --omit=dev --force

# Set Puppeteer environment vars (skip chromium download)
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    CHROME_PATH=/usr/bin/chromium-browser \
    NODE_ENV=production

# Expose the same port your server listens on
EXPOSE 21465

# Start your compiled app
CMD ["node", "dist/index.js"]
