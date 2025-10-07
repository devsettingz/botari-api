# Use a stable Node version that works with sharp and Puppeteer
FROM node:18-alpine AS base
WORKDIR /usr/src/wpp-server

# Environment variables
ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Install required system libraries
RUN apk update && apk add --no-cache \
    vips-dev \
    fftw-dev \
    build-base \
    libc6-compat \
    chromium \
    python3 \
    make \
    g++ \
    gcc

# Copy and install dependencies
COPY package.json yarn.lock* ./
RUN yarn install --production=false --pure-lockfile && yarn cache clean

# Copy rest of project and build
COPY . .
RUN yarn build

# Final stage
FROM node:18-alpine
WORKDIR /usr/src/wpp-server

# Install minimal runtime dependencies
RUN apk add --no-cache chromium vips-dev libc6-compat

ENV NODE_ENV=production
COPY --from=base /usr/src/wpp-server /usr/src/wpp-server

EXPOSE 21465
CMD ["node", "dist/server.js"]
