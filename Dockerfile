FROM node:17.8.0-alpine@sha256:c6fa8b1ea6d027c8fcbe33dee878e5b01c172ea65f3c1aed308008ebbc9db0b2 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.8.0-alpine@sha256:c6fa8b1ea6d027c8fcbe33dee878e5b01c172ea65f3c1aed308008ebbc9db0b2 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.8.0-alpine@sha256:c6fa8b1ea6d027c8fcbe33dee878e5b01c172ea65f3c1aed308008ebbc9db0b2 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]