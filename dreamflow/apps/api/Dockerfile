FROM node:20-alpine AS deps
WORKDIR /app

COPY package*.json ./
COPY apps/api/package*.json ./apps/api/
COPY packages/schemas/package*.json ./packages/schemas/
COPY packages/types/package*.json ./packages/types/

RUN npm ci

FROM deps AS builder
WORKDIR /app

COPY . .
RUN npm run build -w @dreamflow/api

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
COPY apps/api/package*.json ./apps/api/
COPY packages/schemas/package*.json ./packages/schemas/
COPY packages/types/package*.json ./packages/types/

RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist

EXPOSE 3000
CMD ["node", "dist/apps/api/main.js"]
