FROM node:16.11.0-alpine3.13@sha256:9ceec9adb312844a7ed579d4aaa8d95efd80748ba41ee50786eed9f71f904e29 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.11.0-alpine3.13@sha256:9ceec9adb312844a7ed579d4aaa8d95efd80748ba41ee50786eed9f71f904e29 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.11.0-alpine3.13@sha256:9ceec9adb312844a7ed579d4aaa8d95efd80748ba41ee50786eed9f71f904e29 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]