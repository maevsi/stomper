FROM node:16.3.0-alpine3.13@sha256:3e0f83e34a8a3e03d96e78fac8412b83790896c0abd4b112c7f6d0dcef60bca6 AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.3.0-alpine3.13@sha256:3e0f83e34a8a3e03d96e78fac8412b83790896c0abd4b112c7f6d0dcef60bca6 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.3.0-alpine3.13@sha256:3e0f83e34a8a3e03d96e78fac8412b83790896c0abd4b112c7f6d0dcef60bca6 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]