FROM node:18.18.2-alpine@sha256:9632a81cc06b64fd071c31ceb75c6b2d7ce4728ab15a66c328b2e3fa3ef7aedc AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

RUN corepack enable

VOLUME /srv/.pnpm-store
VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pnpm", "run", "dev"]


FROM node:18.18.2-alpine@sha256:9632a81cc06b64fd071c31ceb75c6b2d7ce4728ab15a66c328b2e3fa3ef7aedc AS build

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
    && pnpm install --offline


FROM node:18.18.2-alpine@sha256:9632a81cc06b64fd071c31ceb75c6b2d7ce4728ab15a66c328b2e3fa3ef7aedc AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
