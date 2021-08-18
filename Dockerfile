FROM node:16.6.2-alpine3.13@sha256:5ce99edc816a6923df0844c3d7934bb8da36158097aa8a7183a2c896113d9f9e AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.2-alpine3.13@sha256:5ce99edc816a6923df0844c3d7934bb8da36158097aa8a7183a2c896113d9f9e AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.2-alpine3.13@sha256:5ce99edc816a6923df0844c3d7934bb8da36158097aa8a7183a2c896113d9f9e AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]