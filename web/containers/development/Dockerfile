FROM node:16.14.2-alpine

WORKDIR /app

COPY package.json /app/package.json

RUN apk --no-cache --virtual build-dependencies add \
    && yarn install \
    && apk del build-dependencies
