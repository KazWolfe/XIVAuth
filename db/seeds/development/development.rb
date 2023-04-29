# Create a user with a known ID for consistent verification
superuser = User.new(
  id: 'e5854f0d-fdad-4a76-a208-ec682ec7ffb4',
  email: 'dev@eorzea.id',
  password: 'password'
)
superuser.skip_confirmation!
superuser.save!

superapp = OAuth::Application.new(
  name: 'Seeded Super App',
  owner: superuser,
  confidential: true,
  uid: 'superapp',
  secret: 'superapp_6663def85024',
  redirect_uri: 'http://127.0.0.1:3030/oauth/redirect',
  scopes: 'user user:social user:email user:manage character character:all character:manage'
)
superapp.save!
