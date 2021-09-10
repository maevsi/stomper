FROM node:16.9.0-alpine3.13@sha256:697313d55634a94b36cc5cf75a687b210c7e4a8e433e64d80893bcfca9b11de8 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.9.0-alpine3.13@sha256:697313d55634a94b36cc5cf75a687b210c7e4a8e433e64d80893bcfca9b11de8 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.9.0-alpine3.13@sha256:697313d55634a94b36cc5cf75a687b210c7e4a8e433e64d80893bcfca9b11de8 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]