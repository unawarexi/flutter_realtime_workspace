# ============================================================================
# TeamSpot — Dockerfile
# Multi-stage: development (hot-reload) + production (hardened)
#
# docker compose up          → uses 'development' stage (hot-reload)
# docker build --target production → optimised, non-root, read-only FS
# ============================================================================

# ── Shared base ──────────────────────────────────────────────────────────────
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache wget

# ── Development stage (nodemon hot-reload, mounted source) ───────────────────
FROM base AS development
ENV NODE_ENV=development
ENV PORT=3000

# Install ALL deps (including devDependencies for nodemon/eslint etc.)
COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["npm", "run", "dev"]

# ── Build stage (production deps only) ───────────────────────────────────────
FROM base AS builder
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev
COPY . .

# ── Production stage (hardened, non-root) ────────────────────────────────────
FROM node:20-alpine AS production

LABEL maintainer="TeamSpot"
LABEL description="TeamSpot Enterprise Workspace Backend"

RUN apk add --no-cache wget && \
    addgroup -g 1001 -S teamspot && \
    adduser -S teamspot -u 1001

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder --chown=teamspot:teamspot /app/node_modules ./node_modules
COPY --from=builder --chown=teamspot:teamspot /app .

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

USER teamspot

CMD ["node", "index.js"]
