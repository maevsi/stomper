FROM node:16.5.0-alpine3.13@sha256:2349da8040231bf3141d5d62c70d0ff725c11aef99222939c03969ecc6759e23 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.5.0-alpine3.13@sha256:2349da8040231bf3141d5d62c70d0ff725c11aef99222939c03969ecc6759e23 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.5.0-alpine3.13@sha256:2349da8040231bf3141d5d62c70d0ff725c11aef99222939c03969ecc6759e23 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]