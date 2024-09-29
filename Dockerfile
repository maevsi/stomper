FROM node:22.9.0-alpine AS base-image

WORKDIR /srv/app/

RUN corepack enable

################################################################################
FROM base-image AS development

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/.pnpm-store
VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pnpm", "run", "dev"]

################################################################################
FROM base-image AS prepare

COPY ./pnpm-lock.yaml ./

RUN pnpm fetch

COPY ./ ./

RUN pnpm install --offline

################################################################################
FROM prepare AS lint

RUN pnpm run lint

################################################################################
FROM prepare AS test

RUN pnpm run test --run

################################################################################
FROM prepare AS build

ENV NODE_ENV=production

RUN pnpm run build \
    # Discard development dependencies after building.
    && pnpm install --offline --ignore-scripts

################################################################################
FROM prepare AS collect

COPY --from=build /srv/app/ /srv/app/
COPY --from=lint /srv/app/package.json /tmp/package.json
COPY --from=test /srv/app/package.json /tmp/package.json

################################################################################
FROM collect AS production

ENV NODE_ENV=production

CMD ["pnpm", "run", "start"]
