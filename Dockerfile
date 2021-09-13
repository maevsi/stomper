FROM node:16.9.1-alpine3.13@sha256:2493168624ba845497ae71433a929c58a225e72c4a01b3809f3f4d559c09234b AS development

WORKDIR /srv/app/

COPY ./package.json ./.snyk ./yarn.lock ./

RUN yarn install

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:16.9.1-alpine3.13@sha256:2493168624ba845497ae71433a929c58a225e72c4a01b3809f3f4d559c09234b AS build

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=development /srv/app/ ./

RUN yarn run lint \
    && yarn run test \
    && yarn run build

# Discard devDependencies.
RUN yarn install


FROM node:16.9.1-alpine3.13@sha256:2493168624ba845497ae71433a929c58a225e72c4a01b3809f3f4d559c09234b AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]