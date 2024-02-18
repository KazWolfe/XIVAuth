# XIVAuth

*The last Lodestone verification code you'll ever need.*

> ⚠️ **Here be dragons!**
>
> This application is still undergoing active develpment. There will be bugs, some of which will be dangerous or problematic.
> This application is not yet ready for production use, and will not be for a bit. You've been warned!

XIVAuth is an identity service designed to provide a unified and cohesive authentication solution for websites targeting
players of the critically-acclaimed MMORPG Final Fantasy XIV.

At a high level, XIVAuth allows *users* to create and register (and verify) their character with the service. Other 
sites may then use an OAuth2-like flow to allow users to sign in with either their user account or one (or more) of the
player’s characters. Users only need to register their characters once to be able to use them on any service.

XIVAuth does ***not*** provide Lodestone scraping services, nor does it provide any sort of authorization service; web
services that require Lodestone scraping or have more advanced needs may be better served by XIVAPI or by implementing
their own character verification process. XIVAuth is still able to provide authentication services (and authoritative
validation that a character is verified) to these applications, however. It is best to think of XIVAuth (and its APIs)
as purely an identity and authentication service (really, a dedicated SSO provider) that may tack on additional
character data in an attempt to be useful.

Initial documentation for this project is available [here](https://kazwolfe.notion.site/Documentation-128e77f0016c4901888ea1234678c37d?pvs=4), and will be updated as project development continues.

### Running XIVAuth Locally

To run XIVAuth locally (say, for development purposes), you just need Docker installed and properly configured. In 
theory, all that's necessary to run XIVAuth will be:

```shell
docker compose up
```

However, this is a Rails app and nothing is simple here. In order to access a terminal inside of the container, the 
following command may be used:

```sh
docker compose run app /bin/sh
```

From there, you may use the following commands to initialize the database:

```sh
rake db:create   # required to create the database
rake db:migrate  # required to load all tables
rake db:seed     # required to load in core sample data
```

I would highly recommend just configuring your IDE to handle just running `Procfile.dev` for you, if that's an option.

#### Local Credentials

XIVAuth's development database seed creates an admin user with credetials `dev@eorzea.id` with a password of `password`.
This should be enough to get started with base development, as well as seeing all the various features that XIVAuth has
available to it.

Certain XIVAuth features (particularly OAuth and mailers) require the use of an encrypted credentials file. A sample
file and instructions are present in `config/credentials/sample.yml`. Note that setting up credentials is *not* required
for standard XIVAuth development as the development environment is preconfigured with (insecure) ActiveRecord encryption
keys and Rails itself will take care of generating a `secret_key_base` for development users.