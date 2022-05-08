FROM elixir:1.13.4

ENV LANG C.UTF-8

WORKDIR /app

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
    inotify-tools \
    && mix local.hex --force \
    && mix local.rebar \
    && mix archive.install hex phx_new 1.6.7
