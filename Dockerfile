FROM node:17.0.1-alpine3.13@sha256:068c010cae1788f7de10786977392f3a6ecdc7337098977fba387b22405f0373 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.0.1-alpine3.13@sha256:068c010cae1788f7de10786977392f3a6ecdc7337098977fba387b22405f0373 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.0.1-alpine3.13@sha256:068c010cae1788f7de10786977392f3a6ecdc7337098977fba387b22405f0373 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]