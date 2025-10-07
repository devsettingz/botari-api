# ----------------------------
# Stage 1: Build
# ----------------------------
FROM node:22.20.0-alpine AS build

WORKDIR /usr/src/wpp-server

# Copy package files first (for better caching)
COPY package*.json ./

# Install all dependencies (including devDependencies)
RUN npm install --force

# Copy the rest of your source code
COPY . .

# Build the project (runs build:types + build:js)
RUN npm run build

# ----------------------------
# Stage 2: Runtime
# ----------------------------
FROM node:22.20.0-alpine

WORKDIR /usr/src/wpp-server

# Install Chromium for puppeteer (used by WPPConnect)
RUN apk add --no-cache chromium

# Copy compiled files from build stage
COPY --from=build /usr/src/wpp-server /usr/src/wpp-server

# Expose the server port
EXPOSE 21465

# Start the server
CMD ["npm", "start"]
