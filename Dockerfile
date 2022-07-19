FROM node:18.6.0-alpine@sha256:b3ca07adf425d043e180464aac97cb4f7a566651f77f4ecb87b10c10788644bb AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.6.0-alpine@sha256:b3ca07adf425d043e180464aac97cb4f7a566651f77f4ecb87b10c10788644bb AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.6.0-alpine@sha256:b3ca07adf425d043e180464aac97cb4f7a566651f77f4ecb87b10c10788644bb AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]