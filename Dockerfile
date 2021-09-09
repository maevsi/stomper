FROM node:16.9.0-alpine3.13@sha256:97a4779116fb0776a8a794f6be4826dde6455c5274523a912d84efd855027abc AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.9.0-alpine3.13@sha256:97a4779116fb0776a8a794f6be4826dde6455c5274523a912d84efd855027abc AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.9.0-alpine3.13@sha256:97a4779116fb0776a8a794f6be4826dde6455c5274523a912d84efd855027abc AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]