FROM node:17.1.0-alpine3.13@sha256:de7335267d7b582e6eecee244a4d922301d88abe0c2039e95ab8b608b6ecab80 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.1.0-alpine3.13@sha256:de7335267d7b582e6eecee244a4d922301d88abe0c2039e95ab8b608b6ecab80 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.1.0-alpine3.13@sha256:de7335267d7b582e6eecee244a4d922301d88abe0c2039e95ab8b608b6ecab80 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]