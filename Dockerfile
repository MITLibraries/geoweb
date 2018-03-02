FROM ruby:2.4

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

WORKDIR /geoweb
COPY Gemfile* /geoweb/
RUN bundle install --deployment --without development test

COPY . /geoweb/

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
