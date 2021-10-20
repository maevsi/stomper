FROM node:17.0.0-alpine3.13@sha256:6f1f17e93d76b2760ff385033df86907b216d3f935af8285dd122c87e2a16252 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.0.0-alpine3.13@sha256:6f1f17e93d76b2760ff385033df86907b216d3f935af8285dd122c87e2a16252 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.0.0-alpine3.13@sha256:6f1f17e93d76b2760ff385033df86907b216d3f935af8285dd122c87e2a16252 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]