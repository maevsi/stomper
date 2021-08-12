FROM node:16.6.2-alpine3.13@sha256:bd39f3e62841ba73ed86eec0edfd1b1867ae2153b491545726ece4e328ba54fc AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.2-alpine3.13@sha256:bd39f3e62841ba73ed86eec0edfd1b1867ae2153b491545726ece4e328ba54fc AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.2-alpine3.13@sha256:bd39f3e62841ba73ed86eec0edfd1b1867ae2153b491545726ece4e328ba54fc AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]