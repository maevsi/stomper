FROM node:18.11.0-alpine@sha256:d1e09ed04f228ed68024460e77b777c24025b39d6ee426308aa703fe5282a18d AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["yarn", "run", "dev"]


FROM node:18.11.0-alpine@sha256:d1e09ed04f228ed68024460e77b777c24025b39d6ee426308aa703fe5282a18d AS build

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


FROM node:18.11.0-alpine@sha256:d1e09ed04f228ed68024460e77b777c24025b39d6ee426308aa703fe5282a18d AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
