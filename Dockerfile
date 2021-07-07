FROM node:16.4.1-alpine3.13@sha256:d74699a5c7f53d30afa3c0dec7f963c52dde077ffd7c88c77b7de350abcbe43a AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.4.1-alpine3.13@sha256:d74699a5c7f53d30afa3c0dec7f963c52dde077ffd7c88c77b7de350abcbe43a AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.4.1-alpine3.13@sha256:d74699a5c7f53d30afa3c0dec7f963c52dde077ffd7c88c77b7de350abcbe43a AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]