FROM ruby:2.6.3-alpine

RUN apk add --no-cache build-base postgresql-dev nodejs tzdata shared-mime-info
RUN gem install bundler

WORKDIR /geoweb
COPY Gemfile* /geoweb/
RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'
RUN bundle install

COPY . /geoweb/
RUN mkdir -p /geoweb/tmp/cache/downloads/
# Devise needs a secret key set, but what the key is doesn't matter when
# compiling assets. Use a different secret key when running in production.
RUN \
  SECRET_KEY_BASE=986ba3e063377eee3e36b656ae97c82dfb4d24f835fc98b8dc83a206c41090a10d1b496e40c29cf1506fc6bb38b6475cf01677fa45e9157b4e7c65dd7ce3aeeb \
  RAILS_ENV=production \
  bundle exec rake assets:precompile

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
