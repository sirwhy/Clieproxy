# syntax=docker/dockerfile:1.4

# ── Stage 1: clone + install deps ──────────────────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app

RUN apk add --no-cache git

# Clone dashboard source — semua file ada di sini termasuk package-lock.json
RUN git clone https://github.com/sirwhy/cliproxyapi-dashboard.git .

RUN NODE_OPTIONS=--max-old-space-size=384 npm ci --legacy-peer-deps --no-audit --no-fund && \
    npm cache clean --force

# ── Stage 2: builder ────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

# Copy semua dari deps stage (sudah termasuk source + node_modules)
COPY --from=deps /app ./

# Build-time placeholders — Railway runtime Variables override these
ARG DATABASE_URL="postgresql://build:build@localhost:5432/build"
ARG JWT_SECRET="build-time-placeholder-at-least-32-chars"
ARG MANAGEMENT_API_KEY="build-time-placeholder-16ch"
ARG CLIPROXYAPI_MANAGEMENT_URL="http://127.0.0.1:8317/v0/management"

# Promote ARGs to ENV so zod validation passes during Next.js build
ENV DATABASE_URL=${DATABASE_URL}
ENV JWT_SECRET=${JWT_SECRET}
ENV MANAGEMENT_API_KEY=${MANAGEMENT_API_KEY}
ENV CLIPROXYAPI_MANAGEMENT_URL=${CLIPROXYAPI_MANAGEMENT_URL}

RUN npx prisma generate
RUN NODE_OPTIONS=--max-old-space-size=512 npm run build

# ── Stage 3: runner ─────────────────────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs

RUN apk add --no-cache tini

ARG DASHBOARD_VERSION=railway
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV NEXT_TELEMETRY_DISABLED=1
ENV DASHBOARD_VERSION=${DASHBOARD_VERSION}

COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/messages ./messages
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/src/generated ./src/generated
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nextjs:nodejs /app/prisma.config.ts ./prisma.config.ts
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/prisma ./node_modules/prisma
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/@prisma/engines ./node_modules/@prisma/engines
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/@prisma/adapter-pg ./node_modules/@prisma/adapter-pg
COPY --from=builder --chown=nextjs:nodejs /app/entrypoint.sh ./entrypoint.sh

RUN sed -i 's/\r$//' entrypoint.sh && chmod +x entrypoint.sh
RUN mkdir -p /app/logs /app/backups && chown nextjs:nodejs /app/logs /app/backups

USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
  CMD node -e "fetch('http://localhost:3000/api/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./entrypoint.sh"]
