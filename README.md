# XIVAuth

*The last Lodestone verification code you'll ever need.*

> ⚠️ **Here be dragons!**
>
> This application is still undergoing active development. There will be bugs, some of which will be dangerous or 
> problematic. You've been warned!

XIVAuth is an identity service designed to provide a unified and cohesive authentication solution for websites focusing 
on players of the critically acclaimed MMORPG Final Fantasy XIV.

At a high level, XIVAuth allows *users* to create and register (and verify) their character with the service. Other 
sites may then use an OAuth2-like flow to allow users to sign in with either their user account or one (or more) of the
player’s characters. Users only need to register their characters once to be able to use them on any service.

XIVAuth does ***not*** provide Lodestone scraping services, nor does it provide any sort of authorization service; web
services that require Lodestone scraping or have more advanced needs may be better served by [XIVAPI][xivapi] or by 
implementing their own character verification process. XIVAuth is still able to provide authentication services (and 
authoritative validation that a character is verified) to these applications, however. It is best to think of XIVAuth 
(and its APIs) as purely an identity and authentication service (really, a dedicated SSO provider) that may tack on 
additional character data in an attempt to be useful.

Initial documentation for this project is available [on Notion][notion-docs], and will be updated as project development 
continues.

[notion-docs]: https://kazwolfe.notion.site/Documentation-128e77f0016c4901888ea1234678c37d?pvs=4
[xivapi]: https://v2.xivapi.com/

### Running XIVAuth Locally

To run XIVAuth locally (say, for development purposes), you need Docker installed and properly configured and a `.env`
file set up. A template `development.env` is provided and can just be copied over accordingly. To actually start the
server, all that should be necessary is the following command:

```shell
docker compose up
```

However, this is a Rails app and nothing is simple here. To access a terminal inside the container, the following 
command may be used:

```sh
docker compose run app /bin/sh
```

From there, execute `rake db:setup` to initialize and seed the database with some useful sample data. If you're planning
on doing a lot of development work, consider making a `private.rb` file in `db/seeds/development/` to load any extra
things you might want to include.

If you'd rather run Rails without Docker, this should also work but be aware that you will need to properly configure
all the usual things accordingly.

Regardless, it's probably a better option to just configure your IDE to run `Procfile.dev` for you and manage everything
that way thanks to the watcher paradigm that every web app uses nowadays.

#### Local Credentials

XIVAuth's [development database seed](./db/seeds/development/development.rb) creates an admin user with credentials 
`dev@eorzea.id` with a password of `password`. This should be enough to get started with base development, as well as 
seeing all the various features that XIVAuth has available to it.

Certain XIVAuth features (particularly social login and mailer testing) require the use of an encrypted credentials
file. A sample file and instructions are present in `config/credentials/sample.yml`. Note that setting up credentials
is *not* required for standard XIVAuth development as the development environment is preconfigured with (insecure)
ActiveRecord encryption keys and Rails itself will take care of generating a `secret_key_base` for development users.

Certain data attributes (such as character PKs, verification codes, and similar) are dynamically generated using the
value of `secret_key_base` at application runtime. For local development, Rails will automatically generate this secret
for you and store it in `tmp/local_secret.txt`. If you'd like to override this secret, you may set the environment
variable `SECRET_KEY_BASE`, change the value of `tmp/local_secret.txt`, or add a `secret_key_base` to your development
credentials file. This may be useful if you have multiple development environments and want things to be consistent
between them.
