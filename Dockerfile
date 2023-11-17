FROM oven/bun:1.1.15-alpine AS base-image

WORKDIR /srv/app/

# TODO: remove repository once pnpm lands in main
RUN apk add pnpm --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

################################################################################
FROM base-image AS development

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/.pnpm-store
VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bun", "run", "dev"]

################################################################################
FROM base-image AS prepare

COPY ./pnpm-lock.yaml ./

RUN pnpm fetch

COPY ./ ./

RUN pnpm install --offline

################################################################################
FROM prepare AS lint

RUN bun run lint

################################################################################
FROM prepare AS test

RUN bun run test --run

################################################################################
FROM prepare AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

RUN bun run build \
    # Discard development dependencies after building.
    && pnpm install --offline --ignore-scripts

################################################################################
FROM prepare AS collect

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/
COPY --from=lint /srv/app/package.json /tmp/package.json
COPY --from=test /srv/app/package.json /tmp/package.json

################################################################################
FROM collect AS production

ENV NODE_ENV=production

CMD ["bun", "run", "start"]
