FROM node:13.13.0-alpine3.11@sha256:9c8c3768cfae03a1c55594c1b3797b8611eadc69f37fd46af470ff41837eb488 AS development

WORKDIR /srv/app/

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:13.13.0-alpine3.11@sha256:9c8c3768cfae03a1c55594c1b3797b8611eadc69f37fd46af470ff41837eb488 AS build

WORKDIR /srv/app/

COPY ./package.json ./tsconfig.json ./yarn.lock ./

RUN yarn

COPY ./src/ ./src/

RUN yarn run build


FROM node:13.13.0-alpine3.11@sha256:9c8c3768cfae03a1c55594c1b3797b8611eadc69f37fd46af470ff41837eb488 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]