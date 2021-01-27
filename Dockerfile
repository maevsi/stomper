FROM node:13.14.0-alpine3.11@sha256:01254fbce7320d80f46b9dbfc0620af50c67c4319aff1e53436aea7dbabc8bc0 AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:13.14.0-alpine3.11@sha256:01254fbce7320d80f46b9dbfc0620af50c67c4319aff1e53436aea7dbabc8bc0 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:13.14.0-alpine3.11@sha256:01254fbce7320d80f46b9dbfc0620af50c67c4319aff1e53436aea7dbabc8bc0 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]