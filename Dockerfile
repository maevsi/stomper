FROM node:16.7.0-alpine3.13@sha256:f74b682f5711a09e200c305e08305d18a0d2afe4ec4f8fe925ab080c2118b3e7 AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.7.0-alpine3.13@sha256:f74b682f5711a09e200c305e08305d18a0d2afe4ec4f8fe925ab080c2118b3e7 AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.7.0-alpine3.13@sha256:f74b682f5711a09e200c305e08305d18a0d2afe4ec4f8fe925ab080c2118b3e7 AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]