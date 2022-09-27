FROM node:18.9.1-alpine@sha256:3f2d9530d21df22bdd283203639d59e855aafa424acf72c5875e20a305d4e850 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.9.1-alpine@sha256:3f2d9530d21df22bdd283203639d59e855aafa424acf72c5875e20a305d4e850 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.9.1-alpine@sha256:3f2d9530d21df22bdd283203639d59e855aafa424acf72c5875e20a305d4e850 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]