FROM node:16.3.0-alpine3.13@sha256:6b56197d33a56cd45d1d1214292b8851fa1b91b2ccc678cee7e5fd4260bd8fae AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.3.0-alpine3.13@sha256:6b56197d33a56cd45d1d1214292b8851fa1b91b2ccc678cee7e5fd4260bd8fae AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.3.0-alpine3.13@sha256:6b56197d33a56cd45d1d1214292b8851fa1b91b2ccc678cee7e5fd4260bd8fae AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]