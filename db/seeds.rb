Dir[Rails.root.join("db/seeds/*.rb")].sort.each do |seed|
  load seed
end

Dir[Rails.root.join("db/seeds", Rails.env, "*.rb")].sort.each do |seed|
  load seed
end
