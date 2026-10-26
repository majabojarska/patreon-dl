FROM node:20-bookworm-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build
RUN npm prune --omit=dev

FROM node:20-bookworm-slim

ENV NODE_ENV=production

RUN apt-get update \
    && apt-get install --no-install-recommends -y ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build --chown=node:node /app/package.json /app/package-lock.json ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --from=build --chown=node:node /app/bin ./bin
COPY --from=build --chown=node:node /root/.cache/puppeteer /home/node/.cache/puppeteer

RUN mkdir /data && chown node:node /data
VOLUME ["/data"]
WORKDIR /data

USER node
ENTRYPOINT ["node"]
CMD ["/app/bin/patreon-dl.js"]
