FROM node:14.16.0-alpine3.13@sha256:2c51dc462a02f15621e7486774d36d048a27225d581374b002b8477a79a59b4b AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:14.16.0-alpine3.13@sha256:2c51dc462a02f15621e7486774d36d048a27225d581374b002b8477a79a59b4b AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:14.16.0-alpine3.13@sha256:2c51dc462a02f15621e7486774d36d048a27225d581374b002b8477a79a59b4b AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]