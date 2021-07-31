FROM node:16.6.0-alpine3.13@sha256:36e01fc96f93d48cc31a6cf44d6d2fbd35808b219269740f4c544896d5536c2e AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.0-alpine3.13@sha256:36e01fc96f93d48cc31a6cf44d6d2fbd35808b219269740f4c544896d5536c2e AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.0-alpine3.13@sha256:36e01fc96f93d48cc31a6cf44d6d2fbd35808b219269740f4c544896d5536c2e AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]