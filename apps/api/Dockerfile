# ==============================================================================
# Govia Express.js & Socket.IO API Production Dockerfile
# ==============================================================================
FROM node:20-alpine AS base

RUN apk add --no-cache libc6-compat

# ------------------------------------------------------------------------------
# Stage 1: Dependency installation & Build
# ------------------------------------------------------------------------------
FROM base AS builder
WORKDIR /app

# Copy repository monorepo manifests & source
COPY package.json package-lock.json turbo.json ./
COPY packages ./packages
COPY apps/api ./apps/api

# Install dependencies and build TypeScript to dist/
RUN npm ci
RUN npm run build --workspace=@repo/api

# ------------------------------------------------------------------------------
# Stage 2: Production Runner
# ------------------------------------------------------------------------------
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000
ENV IP_ADDRESS=0.0.0.0

# Create non-root system user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Copy dependency manifests and install production dependencies only
COPY package.json package-lock.json ./
COPY packages ./packages
COPY apps/api/package.json ./apps/api/
RUN npm ci --omit=dev

# Copy compiled distribution and AI legal knowledge base
COPY --from=builder /app/apps/api/dist ./apps/api/dist
COPY --from=builder /app/apps/api/ai-data ./apps/api/ai-data
COPY --from=builder /app/apps/api/src/docs/openapi.json ./apps/api/src/docs/openapi.json

# Create media uploads and winston log folders with non-root ownership
RUN mkdir -p ./apps/api/uploads ./apps/api/winston && \
    chown -R nodejs:nodejs /app

USER nodejs

WORKDIR /app/apps/api

EXPOSE 5000

CMD ["node", "dist/server.js"]
