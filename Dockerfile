FROM node:17.8.0-alpine@sha256:61437e1e517019bd27eb4d3ff6a055096e4a8c048230c2d55ef50d6e970ec608 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.8.0-alpine@sha256:61437e1e517019bd27eb4d3ff6a055096e4a8c048230c2d55ef50d6e970ec608 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.8.0-alpine@sha256:61437e1e517019bd27eb4d3ff6a055096e4a8c048230c2d55ef50d6e970ec608 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]