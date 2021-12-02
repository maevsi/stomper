FROM node:17.2.0-alpine3.13@sha256:ac2e2d12823cd3ec1f2c56e7a3e8b7b8bcea9413e0b5f0f8f266698722640d41 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.2.0-alpine3.13@sha256:ac2e2d12823cd3ec1f2c56e7a3e8b7b8bcea9413e0b5f0f8f266698722640d41 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.2.0-alpine3.13@sha256:ac2e2d12823cd3ec1f2c56e7a3e8b7b8bcea9413e0b5f0f8f266698722640d41 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]