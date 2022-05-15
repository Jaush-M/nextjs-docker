# Development Server
FROM node:18-alpine AS dev
WORKDIR /app
ENV HOST 0.0.0.0
ENV PORT 3000
ENV NODE_ENV development
EXPOSE $PORT
CMD [ "pnpm", "dev" ]

# Install dependencies
FROM node:18-alpine AS deps
RUN corepack enable
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --shamefully-hoist

# Build the source code
FROM node:18-alpine AS builder
RUN corepack enable
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

# Production server
FROM node:18-alpine AS prod

WORKDIR /app

ENV HOST 0.0.0.0
ENV PORT 3000
ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/next.config.js .

COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone .
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE $PORT

CMD ["node", "server.js"]