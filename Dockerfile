FROM node:16.3.0-alpine3.13@sha256:2eee2f439d3b3509bbe40faff6584bd31b5745b4c137e93e2d795899a2927762 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.3.0-alpine3.13@sha256:2eee2f439d3b3509bbe40faff6584bd31b5745b4c137e93e2d795899a2927762 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.3.0-alpine3.13@sha256:2eee2f439d3b3509bbe40faff6584bd31b5745b4c137e93e2d795899a2927762 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]