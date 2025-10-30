web: WEB_CONCURRENCY=auto bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-production} --preload
worker: bundle exec sidekiq -e ${RACK_ENV:-production}
