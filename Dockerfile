FROM node:13.13.0-alpine3.11@sha256:80e4f9b287449c07083854eb11a8bd18209e4c228848295705ae7adfa00a39c9 AS development

WORKDIR /srv/app/

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:13.13.0-alpine3.11@sha256:80e4f9b287449c07083854eb11a8bd18209e4c228848295705ae7adfa00a39c9 AS build

WORKDIR /srv/app/

COPY ./.snyk ./package.json ./tsconfig.json ./yarn.lock ./

RUN yarn

COPY ./src/ ./src/

RUN yarn run build


FROM node:13.13.0-alpine3.11@sha256:80e4f9b287449c07083854eb11a8bd18209e4c228848295705ae7adfa00a39c9 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]