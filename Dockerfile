FROM node:18.9.1-alpine@sha256:566ffe130bb0fd2d03d492333ad2e9c35fcf1f2c9d8be6311b3c29d6c138802a AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.9.1-alpine@sha256:566ffe130bb0fd2d03d492333ad2e9c35fcf1f2c9d8be6311b3c29d6c138802a AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.9.1-alpine@sha256:566ffe130bb0fd2d03d492333ad2e9c35fcf1f2c9d8be6311b3c29d6c138802a AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]