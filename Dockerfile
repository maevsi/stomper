FROM node:18.7.0-alpine@sha256:7d563fd33907c471a57012c722a1cf7ca76a928c2d2145ab114351ba4313b3f8 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.7.0-alpine@sha256:7d563fd33907c471a57012c722a1cf7ca76a928c2d2145ab114351ba4313b3f8 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.7.0-alpine@sha256:7d563fd33907c471a57012c722a1cf7ca76a928c2d2145ab114351ba4313b3f8 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]