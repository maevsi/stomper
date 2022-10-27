FROM node:19.0.0-alpine@sha256:1a04e2ec39cc0c3a9657c1d6f8291ea2f5ccadf6ef4521dec946e522833e87ea AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["yarn", "run", "dev"]


FROM node:19.0.0-alpine@sha256:1a04e2ec39cc0c3a9657c1d6f8291ea2f5ccadf6ef4521dec946e522833e87ea AS build

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


FROM node:19.0.0-alpine@sha256:1a04e2ec39cc0c3a9657c1d6f8291ea2f5ccadf6ef4521dec946e522833e87ea AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
