FROM node:18.7.0-alpine@sha256:b718f847a580064e7ad90103f99509a31a0ca092e6807a84011f28c5a020f80b AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.7.0-alpine@sha256:b718f847a580064e7ad90103f99509a31a0ca092e6807a84011f28c5a020f80b AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.7.0-alpine@sha256:b718f847a580064e7ad90103f99509a31a0ca092e6807a84011f28c5a020f80b AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]