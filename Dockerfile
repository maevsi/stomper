FROM node:16.11.0-alpine3.13@sha256:6d5ecd68b7d28e63fbec26ae4d05fa679a7003325d8e4ea72e6dc318d9869899 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.11.0-alpine3.13@sha256:6d5ecd68b7d28e63fbec26ae4d05fa679a7003325d8e4ea72e6dc318d9869899 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.11.0-alpine3.13@sha256:6d5ecd68b7d28e63fbec26ae4d05fa679a7003325d8e4ea72e6dc318d9869899 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]