FROM ruby:3.2.1-alpine

WORKDIR /app

RUN apk add --update --no-cache \
    build-base git \
    postgresql-dev postgresql-client \
    nodejs yarn npm \
    tzdata

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["rails", "server", "-b", "[::]", "-p", "3000"]
