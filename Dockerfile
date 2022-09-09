FROM node:18.9.0-alpine@sha256:9d18714188f962781e7e7e131d4dfdcc8f11d7724b67ace46eb6ef3e311a6d85 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.9.0-alpine@sha256:9d18714188f962781e7e7e131d4dfdcc8f11d7724b67ace46eb6ef3e311a6d85 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.9.0-alpine@sha256:9d18714188f962781e7e7e131d4dfdcc8f11d7724b67ace46eb6ef3e311a6d85 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]