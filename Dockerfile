FROM node:18.10.0-alpine@sha256:fd5f5b9507f909dee4ba9c5ec554cae3f8d3761fa82f6226df1a269512c6b8eb AS development

WORKDIR /srv/app/

COPY ./package.json ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:18.10.0-alpine@sha256:fd5f5b9507f909dee4ba9c5ec554cae3f8d3761fa82f6226df1a269512c6b8eb AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:18.10.0-alpine@sha256:fd5f5b9507f909dee4ba9c5ec554cae3f8d3761fa82f6226df1a269512c6b8eb AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/package.json /srv/app/package.json
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]