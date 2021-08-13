FROM node:16.6.2-alpine3.13@sha256:64e7fb64b5d6a39566d0ad25c0692d8454fe5f26e40be0f8b9017476f73890c9 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.2-alpine3.13@sha256:64e7fb64b5d6a39566d0ad25c0692d8454fe5f26e40be0f8b9017476f73890c9 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.2-alpine3.13@sha256:64e7fb64b5d6a39566d0ad25c0692d8454fe5f26e40be0f8b9017476f73890c9 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]