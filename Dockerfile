FROM node:17.2.0-alpine3.13@sha256:8828b4aa1fa500dcb2381543fa1e7cf87249b1ef351e8b382347c27092a74126 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.2.0-alpine3.13@sha256:8828b4aa1fa500dcb2381543fa1e7cf87249b1ef351e8b382347c27092a74126 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.2.0-alpine3.13@sha256:8828b4aa1fa500dcb2381543fa1e7cf87249b1ef351e8b382347c27092a74126 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]