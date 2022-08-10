FROM node:18.7.0-alpine@sha256:39eee9aa771257847d3d8bcb7f775439d0267197060053761b54021bcae6338e AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.7.0-alpine@sha256:39eee9aa771257847d3d8bcb7f775439d0267197060053761b54021bcae6338e AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.7.0-alpine@sha256:39eee9aa771257847d3d8bcb7f775439d0267197060053761b54021bcae6338e AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]