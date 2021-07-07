FROM node:16.4.1-alpine3.13@sha256:20127b9ec087e27c91145c6d7438a3272d34e3512073118bbe0ed4ebb8546620 AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.4.1-alpine3.13@sha256:20127b9ec087e27c91145c6d7438a3272d34e3512073118bbe0ed4ebb8546620 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.4.1-alpine3.13@sha256:20127b9ec087e27c91145c6d7438a3272d34e3512073118bbe0ed4ebb8546620 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]