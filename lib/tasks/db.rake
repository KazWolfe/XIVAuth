namespace :db do
  task full_reset: %w[db:migrate:reset db:seed]
end
