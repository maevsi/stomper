FROM node:16.8.0-alpine3.13@sha256:24dcabd9b8315dba05dcc68b9bd372dde47c58367dbd8d273612643d4489ddb0 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.8.0-alpine3.13@sha256:24dcabd9b8315dba05dcc68b9bd372dde47c58367dbd8d273612643d4489ddb0 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.8.0-alpine3.13@sha256:24dcabd9b8315dba05dcc68b9bd372dde47c58367dbd8d273612643d4489ddb0 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]