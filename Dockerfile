FROM node:16.9.1-alpine3.13@sha256:a2b99f95311def1095e5b9604a81956f4109d9a512a44c86fc382f472cad1d91 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.9.1-alpine3.13@sha256:a2b99f95311def1095e5b9604a81956f4109d9a512a44c86fc382f472cad1d91 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.9.1-alpine3.13@sha256:a2b99f95311def1095e5b9604a81956f4109d9a512a44c86fc382f472cad1d91 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]