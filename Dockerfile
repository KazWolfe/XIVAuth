FROM ruby:3.1-alpine

WORKDIR /app

RUN apk add --update --no-cache \
    build-base \
    git \
    postgresql-dev \
    postgresql-client \
    imagemagick \
    nodejs-current \
    yarn \
    tzdata \
    file

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install

COPY lib/docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 3000


CMD ["rails", "server", "-b", "0.0.0.0"]