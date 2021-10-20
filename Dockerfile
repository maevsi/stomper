FROM node:17.0.0-alpine3.13@sha256:4f9a19810ef34eed6deb53ec0dadc04e77db00b89849cc0325e286f6cac31490 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.0.0-alpine3.13@sha256:4f9a19810ef34eed6deb53ec0dadc04e77db00b89849cc0325e286f6cac31490 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.0.0-alpine3.13@sha256:4f9a19810ef34eed6deb53ec0dadc04e77db00b89849cc0325e286f6cac31490 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]