FROM node:17.8.0-alpine@sha256:0f923922724e7d04a699ceb7b92b8383ec093b4e249804c8bd94886426443bff AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.8.0-alpine@sha256:0f923922724e7d04a699ceb7b92b8383ec093b4e249804c8bd94886426443bff AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.8.0-alpine@sha256:0f923922724e7d04a699ceb7b92b8383ec093b4e249804c8bd94886426443bff AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]