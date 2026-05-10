# ============================================================================
# TeamSpot — Dockerfile
# Production Node.js container
# ============================================================================

# ── Build stage ──────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install deps first (cache layer)
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

# Copy application code
COPY . .

# ── Production stage ────────────────────────────────────────────────────────
FROM node:20-alpine AS production

LABEL maintainer="TeamSpot"
LABEL description="TeamSpot Enterprise Workspace Backend"

# Security: run as non-root
RUN addgroup -g 1001 -S teamspot && \
    adduser -S teamspot -u 1001

WORKDIR /app

# Copy from builder
COPY --from=builder --chown=teamspot:teamspot /app/node_modules ./node_modules
COPY --from=builder --chown=teamspot:teamspot /app .

# Environment
ENV NODE_ENV=production
ENV PORT=5000

# Expose
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:5000/health || exit 1

# Switch to non-root user
USER teamspot

# Start
CMD ["node", "index.js"]