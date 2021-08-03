FROM node:16.6.1-alpine3.13@sha256:976d0b9fbb88e2796019615b8a29de54c6559fb887f115dd22e6a2804e0b3063 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.1-alpine3.13@sha256:976d0b9fbb88e2796019615b8a29de54c6559fb887f115dd22e6a2804e0b3063 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.1-alpine3.13@sha256:976d0b9fbb88e2796019615b8a29de54c6559fb887f115dd22e6a2804e0b3063 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]