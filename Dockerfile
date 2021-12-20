FROM node:17.3.0-alpine3.13@sha256:6971395a4f2974dd718e1745c82904c51f6c54ad1f90f7f16b4617f001cf0a70 AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:17.3.0-alpine3.13@sha256:6971395a4f2974dd718e1745c82904c51f6c54ad1f90f7f16b4617f001cf0a70 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:17.3.0-alpine3.13@sha256:6971395a4f2974dd718e1745c82904c51f6c54ad1f90f7f16b4617f001cf0a70 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]