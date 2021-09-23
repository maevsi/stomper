FROM node:16.10.0-alpine3.13@sha256:3da1c08529fef7007d57d2133a0feb0fa8c60fdd4ad6691978f9dfcb0365b430 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.10.0-alpine3.13@sha256:3da1c08529fef7007d57d2133a0feb0fa8c60fdd4ad6691978f9dfcb0365b430 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.10.0-alpine3.13@sha256:3da1c08529fef7007d57d2133a0feb0fa8c60fdd4ad6691978f9dfcb0365b430 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]