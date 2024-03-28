FROM node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75 AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

RUN corepack enable

VOLUME /srv/.pnpm-store
VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pnpm", "run", "dev"]


FROM node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75 AS build

WORKDIR /srv/app/

COPY ./pnpm-lock.yaml ./

RUN corepack enable && \
    pnpm fetch

COPY . .

RUN pnpm install --offline \
    && pnpm run lint \
    && pnpm run test --run

ENV NODE_ENV=production

# Discard development dependencies after building.
RUN pnpm run build \
    && pnpm install --offline --ignore-scripts


FROM node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
