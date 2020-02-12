FROM ruby:alpine
LABEL maintainer=jon@jaggersoft.com

# tar is needed to tar-pipe test coverage out of /tmp tmpfs
RUN apk --update --upgrade --no-cache add bash tar

WORKDIR /app
COPY Gemfile .

RUN apk add --update --upgrade --virtual build-dependencies build-base \
  && echo "gem: --no-rdoc --no-ri" > ~/.gemrc \
  && bundle install \
  && gem clean \
  && apk del build-dependencies build-base \
  && rm -vrf /usr/lib/ruby/gems/*/cache/* \
        /var/cache/apk/* \
        /tmp/* \
        /var/tmp/*

COPY --chown=nobody:nogroup . .

ARG CYBER_DOJO_CREATOR_PORT
ENV PORT=${CYBER_DOJO_CREATOR_PORT}
EXPOSE ${PORT}

USER nobody
CMD [ "/app/up.sh" ]
