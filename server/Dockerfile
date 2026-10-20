# syntax=docker/dockerfile:1
FROM node:22-alpine AS builder

WORKDIR /app
COPY package*.json tsconfig.json ./
RUN npm ci

COPY src ./src
RUN npm run build
RUN npm prune --omit=dev

# Production Runner Stage
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy production node_modules and compiled artifacts with node ownership
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist
COPY --chown=node:node --from=builder /app/package.json ./package.json
# Ordered migrations are read from disk at boot by src/database/migrate.ts.
# schema.sql stays in place for docker-entrypoint-initdb.d on fresh
# Postgres volumes and is not re-executed by the API.
COPY --chown=node:node src/database/schema.sql ./dist/database/schema.sql
COPY --chown=node:node src/database/migrations ./dist/database/migrations

USER node

EXPOSE 4000

CMD ["node", "dist/main.js"]
