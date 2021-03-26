FROM node:14.16.0-alpine3.13@sha256:ee1c7036d8d2a81557eda8b88ecc797676d1db04bf80e7f826512b12d099ee82 AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:14.16.0-alpine3.13@sha256:ee1c7036d8d2a81557eda8b88ecc797676d1db04bf80e7f826512b12d099ee82 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:14.16.0-alpine3.13@sha256:ee1c7036d8d2a81557eda8b88ecc797676d1db04bf80e7f826512b12d099ee82 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]