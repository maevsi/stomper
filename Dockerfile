FROM node:16.8.0-alpine3.13@sha256:abd76715630b2fbed5de9cbcf8b44beb94bfd1ccb972e8dfc3eb5cdf4b1719d0 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.8.0-alpine3.13@sha256:abd76715630b2fbed5de9cbcf8b44beb94bfd1ccb972e8dfc3eb5cdf4b1719d0 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.8.0-alpine3.13@sha256:abd76715630b2fbed5de9cbcf8b44beb94bfd1ccb972e8dfc3eb5cdf4b1719d0 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]