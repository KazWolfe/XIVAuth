require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
]

SimpleCov.start 'rails' do
  track_files "{app,lib}/**/*.rb"
  add_filter "db/migrate"
  add_filter "spec/"
  add_filter "vendor/"

  SimpleCov.coverage_dir "tmp/testresults/coverage"
end