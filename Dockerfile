FROM elixir:1.11-alpine AS builder

# The following are build arguments used to change variable parts of the image.
# The name of your application/release (required)
ARG APP_NAME=geo_tasks
# The environment to build with
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME}
ENV MIX_ENV=${MIX_ENV}

WORKDIR /${APP_NAME}

# This step installs all the build tools we'll need
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
    openssh-client \
    build-base && \
  mix local.rebar --force && \
  mix local.hex --force

# This copies our app source code into the build container
COPY . .

RUN mix do deps.get --only ${MIX_ENV}, deps.compile, compile, release



# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:latest

# The name of your application/release
ARG APP_NAME=geo_tasks
# The environment to build with
ARG MIX_ENV=prod

RUN apk update && \
    apk add --no-cache \
      bash \
      openssl-dev

ENV APP_NAME=${APP_NAME}
ENV MIX_ENV=${MIX_ENV}

WORKDIR /${APP_NAME}

COPY --from=builder /${APP_NAME}/_build/${MIX_ENV}/rel/${APP_NAME} .

CMD trap 'exit' INT; /${APP_NAME}/bin/${APP_NAME} start
