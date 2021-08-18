FROM node:16.6.2-alpine3.13@sha256:ddc40542dad68027d6963d562695bc63a91c0525500aad5fa9689167b87e256a AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.2-alpine3.13@sha256:ddc40542dad68027d6963d562695bc63a91c0525500aad5fa9689167b87e256a AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.2-alpine3.13@sha256:ddc40542dad68027d6963d562695bc63a91c0525500aad5fa9689167b87e256a AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]