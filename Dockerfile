FROM node:16.6.2-alpine3.13@sha256:22e6e08e5be7d772daf552e0ac273fd6304bd9c374e5e1596dd4fe5e8c241e1e AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.2-alpine3.13@sha256:22e6e08e5be7d772daf552e0ac273fd6304bd9c374e5e1596dd4fe5e8c241e1e AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.2-alpine3.13@sha256:22e6e08e5be7d772daf552e0ac273fd6304bd9c374e5e1596dd4fe5e8c241e1e AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]