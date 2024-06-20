FROM node:18.20.3-alpine@sha256:ce8c18ad1dc0f9b980698e6de7a31293a7c95b0e8b8b3560270c1aff6d3eeeb6 AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

RUN corepack enable

VOLUME /srv/.pnpm-store
VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pnpm", "run", "dev"]


FROM node:18.20.3-alpine@sha256:ce8c18ad1dc0f9b980698e6de7a31293a7c95b0e8b8b3560270c1aff6d3eeeb6 AS build

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


FROM node:18.20.3-alpine@sha256:ce8c18ad1dc0f9b980698e6de7a31293a7c95b0e8b8b3560270c1aff6d3eeeb6 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
