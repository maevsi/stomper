FROM node:17.8.0-alpine@sha256:29b18ec3a6e20178c4284e57649aa543a35bcd27d674600f90e9dc974130393c AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.8.0-alpine@sha256:29b18ec3a6e20178c4284e57649aa543a35bcd27d674600f90e9dc974130393c AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.8.0-alpine@sha256:29b18ec3a6e20178c4284e57649aa543a35bcd27d674600f90e9dc974130393c AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]