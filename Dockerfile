FROM node:13.12.0-alpine3.11@sha256:ed06820d0fb6f4711e0a6f50c9f147fb2596399866319e1bb3b0a52393c5615f AS development

WORKDIR /srv/app/

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:13.12.0-alpine3.11@sha256:ed06820d0fb6f4711e0a6f50c9f147fb2596399866319e1bb3b0a52393c5615f AS build

WORKDIR /srv/app/

COPY ./package.json ./tsconfig.json ./yarn.lock ./

RUN yarn

COPY ./src/ ./src/

RUN yarn run build


FROM node:13.12.0-alpine3.11@sha256:ed06820d0fb6f4711e0a6f50c9f147fb2596399866319e1bb3b0a52393c5615f AS production

ENV NODE_ENV=production

WORKDIR /srv/app/

COPY --from=build /srv/app/dist/ /srv/app/dist/
COPY --from=build /srv/app/node_modules/ /srv/app/node_modules/

CMD ["node", "./dist/stomper.js"]