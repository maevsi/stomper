FROM node:17.1.0-alpine3.13@sha256:96a10ba6aee0b06b1b014c26aedd39c6fe51b1724e763a45cd712293117fe36d AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.1.0-alpine3.13@sha256:96a10ba6aee0b06b1b014c26aedd39c6fe51b1724e763a45cd712293117fe36d AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.1.0-alpine3.13@sha256:96a10ba6aee0b06b1b014c26aedd39c6fe51b1724e763a45cd712293117fe36d AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]