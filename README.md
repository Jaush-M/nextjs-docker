# Next.js + Tailwind CSS + PNPM + Docker Example

This example shows how to use Docker with Next.js based on the [deployment documentation](https://nextjs.org/docs/deployment#docker-image).

## Installing pnpm

When using npm or Yarn, if you have 100 projects using a dependency, you will have 100 copies of that dependency saved on disk. With pnpm, the dependency will be stored in a content-addressable store

### Using corepack

Since v16.13, Node.js is shipping Corepack for managing package managers. This is an experimental feature, so you need to enable it by running:

```
corepack enable
```

### Using Homebrew

If you have the homebrew package manager installed, you can install pnpm using the following command:

```
brew install pnpm
```

## How to use

Execute [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app) with [pnpm](https://pnpm.io/cli/create) to bootstrap the example:

```bash
pnpm create next-app -- -e with-tailwindcss nextjs-docker
```

## Standalone Server

Automatically leverage [output traces](https://nextjs.org/docs/advanced-features/output-file-tracing) to reduce the image size.

To leverage this automatic copying you have to first enable it in your `next.config.js`:

```js
// next.config.js
module.exports = {
  // ... rest of the configuration.
  experimental: {
    outputStandalone: true,
  },
}
```

For a `production environment`, it is strongly recommended you install `sharp` to your project directory.

```
% pnpm install sharp
```

### Dockerfile

```docker
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
```

## Using Docker

1. [Install Docker](https://docs.docker.com/get-docker/) on your machine.
2. For production build: `docker build -t <tag> --target prod .` or development build: `docker build -t <tag> --target dev .`.
3. Run production container: `docker run --rm --name <name> -dp 3000:3000 <tag>` or development build: `docker run --rm -it --name <name> -p 3000:3000 -v ${PWD}:/app -w /app <tag>`.

You can view your images created with `docker images`, and containers using `docker ps`.
