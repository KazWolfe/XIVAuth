ARG RUBY_VERSION=3.4.7
FROM ruby:${RUBY_VERSION}-alpine AS base

WORKDIR /app

ENV BUNDLE_PATH="/usr/local/bundle"
RUN gem update --system --no-document && \
    gem install -N bundler foreman

# Install base packages
RUN apk add --no-cache curl jemalloc postgresql-client tzdata libsodium



# -----------------------------
# Dev and Builder Stage
FROM base AS dev

RUN apk add --no-cache build-base gcompat git postgresql-dev nodejs yarn npm libsodium-dev yaml-dev

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

ENTRYPOINT ["/app/bin/docker-entrypoint"]
CMD ["/app/bin/rails", "server", "-b", "[::]", "-p", "3000"]



# -----------------------------
# Asset Stage
FROM dev AS assets
RUN bundle exec bootsnap precompile --gemfile && \
    bundle exec bootsnap precompile app/ lib/ && \
    RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rake assets:precompile



# -----------------------------
# Release Image
FROM base AS release

RUN apk add --no-cache libpq
COPY --from=assets "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=assets /app /app

ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production"

RUN addgroup --system --gid 1000 appsrv && \
    adduser --system appsrv --uid 1000 --ingroup appsrv --home /home/appsrv --shell /bin/sh appsrv && \
    chown -R 1000:1000 db log storage tmp
USER 1000:1000