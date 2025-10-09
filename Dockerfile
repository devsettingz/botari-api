# ----------------------------
# Stage 1: Build
# ----------------------------
FROM node:22.20.0-alpine AS build

WORKDIR /usr/src/wpp-server

# Copy package files first (for better caching)
COPY package*.json ./

# ✅ Install dependencies (including devDependencies)
RUN npm install --legacy-peer-deps

# Copy the rest of your source code
COPY . .

# ✅ Build the TypeScript project (creates dist/)
RUN npm run build

# ----------------------------
# Stage 2: Runtime
# ----------------------------
FROM node:22.20.0-alpine

WORKDIR /usr/src/wpp-server

# ✅ Install Chromium for Puppeteer/WPPConnect
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Copy compiled app from build stage
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./

# ✅ Install only production dependencies
RUN npm install --omit=dev --legacy-peer-deps

# Expose the server port
EXPOSE 21465

# ✅ Environment vars for Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    CHROME_PATH=/usr/bin/chromium-browser \
    NODE_ENV=production

# Start the server
CMD ["node", "dist/server.js"]
