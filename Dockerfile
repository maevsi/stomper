FROM node:19.1.0-alpine@sha256:c59fb39150e4a7ae14dfd42d3f9874398c7941784b73049c2d274115f00d36c8 AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

RUN npm install -g pnpm

VOLUME /srv/.pnpm-store
VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pnpm", "run", "dev"]


FROM node:19.1.0-alpine@sha256:c59fb39150e4a7ae14dfd42d3f9874398c7941784b73049c2d274115f00d36c8 AS build

WORKDIR /srv/app/

COPY ./pnpm-lock.yaml ./

RUN npm install -g pnpm && \
    pnpm fetch

COPY . .

RUN pnpm install --offline \
    && pnpm run lint \
    && pnpm run test

ENV NODE_ENV=production

# Discard development dependencies after building.
RUN pnpm run build \
    && pnpm install --offline


FROM node:19.1.0-alpine@sha256:c59fb39150e4a7ae14dfd42d3f9874398c7941784b73049c2d274115f00d36c8 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
