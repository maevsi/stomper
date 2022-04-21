FROM node:18.0.0-alpine@sha256:469ee26d9e00547ea91202a34ff2542f984c2c60a2edbb4007558ccb76b56df2 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.0.0-alpine@sha256:469ee26d9e00547ea91202a34ff2542f984c2c60a2edbb4007558ccb76b56df2 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.0.0-alpine@sha256:469ee26d9e00547ea91202a34ff2542f984c2c60a2edbb4007558ccb76b56df2 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]