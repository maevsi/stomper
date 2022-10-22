FROM node:19.0.0-alpine@sha256:bdd47da7e6d246549db69891f5865d82dfc9961eae897197d85a030f254980b1 AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["yarn", "run", "dev"]


FROM node:19.0.0-alpine@sha256:bdd47da7e6d246549db69891f5865d82dfc9961eae897197d85a030f254980b1 AS build

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


FROM node:19.0.0-alpine@sha256:bdd47da7e6d246549db69891f5865d82dfc9961eae897197d85a030f254980b1 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
