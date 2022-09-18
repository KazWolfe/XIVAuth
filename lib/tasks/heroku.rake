namespace :heroku do
  task :release do
    Rake::Task['db:migrate'].invoke
  end
end