FROM node:16.6.2-alpine3.13@sha256:4e70ed424e6310602d6137b353cc3e0ae066c4214ce17967ca9336b80b3a7fbd AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.2-alpine3.13@sha256:4e70ed424e6310602d6137b353cc3e0ae066c4214ce17967ca9336b80b3a7fbd AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.2-alpine3.13@sha256:4e70ed424e6310602d6137b353cc3e0ae066c4214ce17967ca9336b80b3a7fbd AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]