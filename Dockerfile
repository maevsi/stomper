FROM node:16.6.1-alpine3.13@sha256:53ebfa5e6df1e458b47f677cb4f6fd3cf1d079083647dc40d182910a57b5a63d AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.6.1-alpine3.13@sha256:53ebfa5e6df1e458b47f677cb4f6fd3cf1d079083647dc40d182910a57b5a63d AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.6.1-alpine3.13@sha256:53ebfa5e6df1e458b47f677cb4f6fd3cf1d079083647dc40d182910a57b5a63d AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]