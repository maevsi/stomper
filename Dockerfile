FROM node:14.16.0-alpine3.13@sha256:7eb57d8fd2d3ee789dbb551bdf5b0325369c3ad7a72a690e80d034041da7e42d AS development

# https://github.com/typicode/husky/issues/821
ENV HUSKY_SKIP_INSTALL=1

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:14.16.0-alpine3.13@sha256:7eb57d8fd2d3ee789dbb551bdf5b0325369c3ad7a72a690e80d034041da7e42d AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint
RUN yarn run test
RUN yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:14.16.0-alpine3.13@sha256:7eb57d8fd2d3ee789dbb551bdf5b0325369c3ad7a72a690e80d034041da7e42d AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]