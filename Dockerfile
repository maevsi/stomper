FROM node:16.6.0-alpine3.13@sha256:a55cd676d1aec59d871855b86984063c8854e67a7f552af66418c5068103a509 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.0-alpine3.13@sha256:a55cd676d1aec59d871855b86984063c8854e67a7f552af66418c5068103a509 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.0-alpine3.13@sha256:a55cd676d1aec59d871855b86984063c8854e67a7f552af66418c5068103a509 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]