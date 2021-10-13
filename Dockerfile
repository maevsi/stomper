FROM node:16.11.1-alpine3.13@sha256:417b3856d2e5d06385123f3924c36f5735fb1f690289ca69f2ac9c35fd06c009 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.11.1-alpine3.13@sha256:417b3856d2e5d06385123f3924c36f5735fb1f690289ca69f2ac9c35fd06c009 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.11.1-alpine3.13@sha256:417b3856d2e5d06385123f3924c36f5735fb1f690289ca69f2ac9c35fd06c009 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]