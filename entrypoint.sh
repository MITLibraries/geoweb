#!/bin/sh
set -e

bundle exec rake db:setup || bundle exec rake db:migrate
# This seems to be necessary when reusing the same image, e.g. during
# docker restart
rm -f tmp/pids/server.pid
bundle exec rails s -p 8001 -b 0.0.0.0
