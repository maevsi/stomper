FROM node:20.2.0-alpine@sha256:f3fe00fbf0cd0660487f3133a2a4bf16d0778198fdc94a08eb6558ebf9c39f57 AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

RUN corepack enable

VOLUME /srv/.pnpm-store
VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pnpm", "run", "dev"]


FROM node:20.2.0-alpine@sha256:f3fe00fbf0cd0660487f3133a2a4bf16d0778198fdc94a08eb6558ebf9c39f57 AS build

WORKDIR /srv/app/

COPY ./pnpm-lock.yaml ./

RUN corepack enable && \
    pnpm fetch

COPY . .

RUN pnpm install --offline \
    && pnpm run lint \
    && pnpm run test

ENV NODE_ENV=production

# Discard development dependencies after building.
RUN pnpm run build \
    && pnpm install --offline


FROM node:20.2.0-alpine@sha256:f3fe00fbf0cd0660487f3133a2a4bf16d0778198fdc94a08eb6558ebf9c39f57 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
