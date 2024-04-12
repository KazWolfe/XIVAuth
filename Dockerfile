FROM ruby:3.3.0-alpine

WORKDIR /app

RUN apk add --update --no-cache \
    build-base git \
    postgresql-dev postgresql-client \
    nodejs yarn npm \
    tzdata \
    libsodium libsodium-dev

# Required for local dev shenanigans, because we can't add Foreman to the gemfile.
# See https://www.jdeen.com/blog/don-t-add-foreman-to-your-gemfile
RUN gem install foreman

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

ENTRYPOINT ["bin/docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "[::]", "-p", "3000"]
