FROM node:13.12.0-alpine3.11@sha256:ed06820d0fb6f4711e0a6f50c9f147fb2596399866319e1bb3b0a52393c5615f AS development

WORKDIR /app/

COPY ./ ./

CMD ["yarn", "run", "dev"]


FROM node:13.12.0-alpine3.11@sha256:ed06820d0fb6f4711e0a6f50c9f147fb2596399866319e1bb3b0a52393c5615f AS build

WORKDIR /app/

COPY ./package.json ./tsconfig.json ./yarn.lock ./

RUN yarn

COPY ./src/ ./src/

RUN yarn run build


FROM node:13.12.0-alpine3.11@sha256:ed06820d0fb6f4711e0a6f50c9f147fb2596399866319e1bb3b0a52393c5615f AS production

ENV NODE_ENV=production

WORKDIR /app/

COPY --from=build /app/dist/ /app/dist/
COPY --from=build /app/node_modules/ /app/node_modules/

CMD ["node", "./dist/stomper.js"]