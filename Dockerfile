FROM node:18.10.0-alpine@sha256:f829c27f4f7059609e650023586726a126db25aded0c401e836cb81ab63475ff AS development

WORKDIR /srv/app/

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["yarn", "run", "dev"]


FROM node:18.10.0-alpine@sha256:f829c27f4f7059609e650023586726a126db25aded0c401e836cb81ab63475ff AS build

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


FROM node:18.10.0-alpine@sha256:f829c27f4f7059609e650023586726a126db25aded0c401e836cb81ab63475ff AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]
