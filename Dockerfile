FROM node:16.9.0-alpine3.13@sha256:a25ca168fccced6852b89728ddfda1309addcd6f307f3db067e48ba2d58248ed AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.9.0-alpine3.13@sha256:a25ca168fccced6852b89728ddfda1309addcd6f307f3db067e48ba2d58248ed AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.9.0-alpine3.13@sha256:a25ca168fccced6852b89728ddfda1309addcd6f307f3db067e48ba2d58248ed AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]