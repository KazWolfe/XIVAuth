ActiveRecord::Base.transaction do
  ['common', Rails.env].each do |environment|
    seed_dir = "#{Rails.root}/db/seeds/#{environment}/"
    if File.directory?(seed_dir)
      Dir.foreach(seed_dir) do |seed_file|
        next if seed_file == '.' or seed_file == '..'

        puts "- - Seeding data from file: #{environment}/#{seed_file}"
        require "#{seed_dir}/#{seed_file}"
      end
    end
  end
end