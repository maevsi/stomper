FROM node:16.6.0-alpine3.13@sha256:47af330a6d6dcb706a3fadf3ecebe50f73064831991f9a4c5f21a46cfc6d97d7 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.0-alpine3.13@sha256:47af330a6d6dcb706a3fadf3ecebe50f73064831991f9a4c5f21a46cfc6d97d7 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.0-alpine3.13@sha256:47af330a6d6dcb706a3fadf3ecebe50f73064831991f9a4c5f21a46cfc6d97d7 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]