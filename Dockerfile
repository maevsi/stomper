FROM node:18.8.0-alpine@sha256:8437bc872a71f3b15a384ff32d098a68e06b440c0d9ec3eb4b4fa26ca16f2b30 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.8.0-alpine@sha256:8437bc872a71f3b15a384ff32d098a68e06b440c0d9ec3eb4b4fa26ca16f2b30 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.8.0-alpine@sha256:8437bc872a71f3b15a384ff32d098a68e06b440c0d9ec3eb4b4fa26ca16f2b30 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]