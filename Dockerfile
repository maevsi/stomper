FROM node:14.16.0-alpine3.13@sha256:b16801f4e3518cfe639e7074a3fa34cc4262de82f09b4e2db5fe29c7dbd6cf2b AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:14.16.0-alpine3.13@sha256:b16801f4e3518cfe639e7074a3fa34cc4262de82f09b4e2db5fe29c7dbd6cf2b AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:14.16.0-alpine3.13@sha256:b16801f4e3518cfe639e7074a3fa34cc4262de82f09b4e2db5fe29c7dbd6cf2b AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]