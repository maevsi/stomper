FROM node:16.7.0-alpine3.13@sha256:597864180891b2498e104ace823507882aa9ae132115af63dd8fc611bb300984 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.7.0-alpine3.13@sha256:597864180891b2498e104ace823507882aa9ae132115af63dd8fc611bb300984 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.7.0-alpine3.13@sha256:597864180891b2498e104ace823507882aa9ae132115af63dd8fc611bb300984 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]