FROM node:19.0.1-alpine@sha256:083a23fe246cc82294f64e154f5d6bce8c90b9fc8f2dce54d3c58d41ddd8f8c8 AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["yarn", "run", "dev"]


FROM node:19.0.1-alpine@sha256:083a23fe246cc82294f64e154f5d6bce8c90b9fc8f2dce54d3c58d41ddd8f8c8 AS build

WORKDIR /srv/app/

COPY package.json yarn.lock ./

RUN yarn install

COPY . .

RUN yarn run lint \
    && yarn run test

ENV NODE_ENV=production

# Discard development dependencies after building.
RUN yarn run build \
    && yarn install


FROM node:19.0.1-alpine@sha256:083a23fe246cc82294f64e154f5d6bce8c90b9fc8f2dce54d3c58d41ddd8f8c8 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
