FROM node:18.9.0-alpine@sha256:370c4e3b4da19d62f0afc7e6c5f78e3d28d861680c324144a56141fd43c1498c AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.9.0-alpine@sha256:370c4e3b4da19d62f0afc7e6c5f78e3d28d861680c324144a56141fd43c1498c AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.9.0-alpine@sha256:370c4e3b4da19d62f0afc7e6c5f78e3d28d861680c324144a56141fd43c1498c AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]