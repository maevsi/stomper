FROM node:16.4.2-alpine3.13@sha256:b7e2d75ecd585feed57be69cd3dee973e5c498241e64906899b3baa2169fb35a AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.4.2-alpine3.13@sha256:b7e2d75ecd585feed57be69cd3dee973e5c498241e64906899b3baa2169fb35a AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.4.2-alpine3.13@sha256:b7e2d75ecd585feed57be69cd3dee973e5c498241e64906899b3baa2169fb35a AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]