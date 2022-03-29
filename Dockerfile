FROM node:17.8.0-alpine@sha256:0c88ddeb949638cbaa8438a95aff1fce0e7c83e09c6f154245a1a8b0a1becd9e AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.8.0-alpine@sha256:0c88ddeb949638cbaa8438a95aff1fce0e7c83e09c6f154245a1a8b0a1becd9e AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.8.0-alpine@sha256:0c88ddeb949638cbaa8438a95aff1fce0e7c83e09c6f154245a1a8b0a1becd9e AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]