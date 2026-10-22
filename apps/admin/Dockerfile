# ==============================================================================
# Govia Admin Dashboard Production Dockerfile (Next.js Standalone)
# ==============================================================================
FROM node:20-alpine AS base

# Install libc6-compat for alpine compatibility if needed
RUN apk add --no-cache libc6-compat

# ------------------------------------------------------------------------------
# Stage 1: Dependency installation & Build
# ------------------------------------------------------------------------------
FROM base AS builder
WORKDIR /app

# Client-side environment build arguments
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_SOCKET_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NEXT_PUBLIC_SOCKET_URL=${NEXT_PUBLIC_SOCKET_URL}

# Copy repository monorepo manifests
COPY package.json package-lock.json turbo.json ./
COPY packages ./packages
COPY apps/admin ./apps/admin

# Install dependencies and build standalone bundle
RUN npm ci
RUN npm run build --workspace=@repo/admin

# ------------------------------------------------------------------------------
# Stage 2: Production Runner
# ------------------------------------------------------------------------------
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Create non-root system user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy static assets and public directory (both root and app relative)
COPY --from=builder /app/apps/admin/public ./apps/admin/public
COPY --from=builder /app/apps/admin/public ./public

# Copy Next.js standalone output
COPY --from=builder --chown=nextjs:nodejs /app/apps/admin/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/admin/.next/static ./apps/admin/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/apps/admin/.next/static ./.next/static

USER nextjs

EXPOSE 3000

# Built-in healthcheck for zero-downtime blue/green deployments
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:3000/').then(r=>{if(r.status>=500)process.exit(1)}).catch(()=>process.exit(1))"

CMD ["node", "apps/admin/server.js"]
