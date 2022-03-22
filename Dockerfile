FROM node:17.7.2-alpine@sha256:0fd72c52a9cd4d0f862bec97778bb1e71705aa57699b0e2976152d2e434ce2f5 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.7.2-alpine@sha256:0fd72c52a9cd4d0f862bec97778bb1e71705aa57699b0e2976152d2e434ce2f5 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.7.2-alpine@sha256:0fd72c52a9cd4d0f862bec97778bb1e71705aa57699b0e2976152d2e434ce2f5 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]