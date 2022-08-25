FROM node:18.8.0-alpine@sha256:d5d7d8e860cb38063ac0735753bed467d1360ece5ccb7c99747726bb9399ccfa AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.8.0-alpine@sha256:d5d7d8e860cb38063ac0735753bed467d1360ece5ccb7c99747726bb9399ccfa AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.8.0-alpine@sha256:d5d7d8e860cb38063ac0735753bed467d1360ece5ccb7c99747726bb9399ccfa AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]