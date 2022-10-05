FROM node:18.10.0-alpine@sha256:d4935e4a77d3a9aca897dc3610f7a9abc83732ba4075439fbdb46a517c07d81e AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["yarn", "run", "dev"]


FROM node:18.10.0-alpine@sha256:d4935e4a77d3a9aca897dc3610f7a9abc83732ba4075439fbdb46a517c07d81e AS build

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


FROM node:18.10.0-alpine@sha256:d4935e4a77d3a9aca897dc3610f7a9abc83732ba4075439fbdb46a517c07d81e AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
