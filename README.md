# XIVAuth

XIVAuth is a service designed to make authenticating characters in Final Fantasy XIV simple, clean, and convenient.

## Features

* OAuth Provider allows other sites to leverage XIVAuth for signin
  * Three modes: Single Character, User, Multi-Character - dev-selectable
    * Single Character (`character`): Default mode, info for *only* the authenticated character is returned, no user data.
      * Useful for apps that want to authenticate against a specific character for something.
      * Can only be used with verified characters.
    * User (`user` or `openid`): Info for *only* the authenticate a specific user.
      * Useful for apps that want to authenticate against a player, esp. for deduplication.
      * WILL expose if user has verified characters, but not how many.
      * Can be used if user doesn't have verified characters.
    * Multi-Character (`character:all`): Hybrid of above. Returns user + one or more associated characters.
      * User decides which character to share (one, some, all).
      * Receiving app will not know what user selects.
      * Receiving app *can* request single-character response.
      * Can only be used if user has verified characters.
    * API Access: Highly restricted scope, basically gives near-total access to account.
      * Provided for services like Dalamud or certain plugins to read from/write to XIVAuth account
      * ex uses: auto-registering new accounts (non-verified), generating attestation tokens

### Attestation Token

In some cases, it may be necessary for a system to verify a user's identity without requiring a direct OAuth sign-in
for one reason or another. One such example of this is a Dalamud plugin that communicates with a backend server. The 
plugin cannot simply trust the client to be truthful about the logged in character (perhaps the code has been borrowed),
so XIVAuth can step in to perform verification. 

In this scenario, the following conditions are present:
- Dalamud has an XIVAuth service present within itself, which has API access to an XIVAuth account.
- The player is playing on a character "Popoto Poto", which the server would like to verify.
- The player is logged in to their XIVAuth account, and Popoto Poto is a verified character on that account.

In the above case, the plugin can request an attestation that Popoto Poto does actually belong to the registered XIVAuth
account, and can use that authentication as validation for whatever it needs.

1. The plugin opens a session with its backend server, and requests a nonce variable to use for verification.
2. The plugin uses a Dalamud API to request attestation for the current user (Popoto Poto), with a specified nonce.
3. Dalamud creates and sends an (authenticated) request to XIVAuth to generate the Attestation Token.
4. The XIVAuth server validates the request and generates a signed attestation, sent in the HTTP response.
5. Dalamud passes the attestation to the plugin, which then passes it to the plugin's backend server.
6. The plugin's backend server verifies the digital signature on the attestation and ensures the nonce/expiration is valid.
7. The server and plugin perform application-specific implementations knowing the player is verified.

Note, though, that Attestation Tokens are not perfect. They have a few caveats:

1. There is no way to trust that the logged in player is actually the attested player. Dalamud can request an
   attestation for any character associated with the account. All the Attestation Token proves is that a character with
   the requested Lodestone ID is bound to an XIVAuth account, and that the client is logged in to that XIVAuth account.
2. A rogue plugin server can merely proxy an attestation to somewhere else. While the nonce blocks replay, a malicious
   backend server can act as a middleman for an attestation and "prove" a login to a different service and create its
   own session. 

Possible room for improvement is the fact that the plugin server can merely proxy the attestation to somewhere else. 
While the nonce blocks replay (the response must be to the request), a rogue plugin server can pass the attestation 
forward for its own nefarious purposes (e.g. a plugin server logging on to another server). Plus, oauth itself still 
has this issue to some degree, where rogue proxies are possible.

Attestation tokens are customizable - the client requesting the token may return whatever subset of information it wants
to return, but this is left strictly to the client to manage. For example, if Dalamud were to request a verified JWT for
a specific character, Dalamud would have to specify that *only* information about the specific character is permitted.
An attestation token can only ever carry information about a single character and a single user at any given time; no
multi-character tokens may be generated or used through this system. 

### Scopes

The following scopes are available:

* `character`: Base scope for character access. Will only allow the user to log in with a specific character, and a character must be selected.
  * `character:all`: Scope to access some/all (verified) characters. User will be given the option to select which characters to grant. Can return zero characters if the user elects to not share any.
  * `character:manage`: Allow adding/removing characters, and seeing unverified characters. Applies to *all* characters.
* `user`: Base scope for read-only user access. Will return base profile information, including username and if the user has any verified characters.
  * `openid`: Alias to `user`. Does not grant additional permissions.
  * `user:email`: Allows reading the user's email address. *Can be declined by user.*
* `jwt`: Allows generating JWTs for the user, generally for delegated authentication (see Attestation).
* `refresh`: Requests a refresh token for persistent authentication.

An application created by a user can choose *only* between the `character` and the `user` scope. Applications that 
require multiple or other scopes will need approval from a project maintainer. Scopes will *never* cross the user
boundary. The `character:manage` and `jwt` scopes will require extra scrutiny and are generally reserved for key
projects such as Dalamud or XL that perform deeper integration into XIVAuth and its services.

If a service requires at least one character to be selected *and* allows more to be selected as well, it should use the
scope declaration `character character:all`. 

Refresh tokens will only be issued to applications that require programmatic access to XIVAuth itself or mutating data.
Due to the general nature of XIVAuth's services, this really only applies to applications with the scope 
`character_all`, `character:manage`, or `jwt`. Access to the `refresh` scope must be approved manually.

## Sidebar

* **Profile**
  * Edit Email, Password, MFA
  * Link/Unlink OAuth Providers (Discord, Steam, etc.)
  * Delete Account
* **Characters**
  * Add/Remove Character
  * Verify Character
* **API Keys** / **Game Clients**
  * List API Keys (certain services)
  * List Game Clients (certain other services?) - this is probably just a special oauth
* **Connected Applications** (persistent apps?)
  * Revoke App / Edit Permissions
* **Developer**
  * Request Access (Only for non-developers)
  * Applications
* **Admin**: System maintenance panel for users of XIVAuth
  * **Users**: List of all users registered
    * Merge User
    * Ban User / Delete User
    * Reset Password / MFA
    * Update User Permissions
    * List/Edit Linked Characters (mini-view of Characters table)
    * List/Remove API Keys/Clients
    * View/Unlink OAuth Providers
    * Fuck Fraud Tool Kit
  * **Characters**: List and take action on characters
    * Delete Character
    * Force/Revoke Verification Status
    * Move Character to User
    * Ban Character
  * **Developer Management**: Manage registered apps
    * List Apps
    * Disable App
    * Revoke App Credentials (Security)
  * **Features**: Toggle Feature Flags

## Progress List

- User Management
  - [x] Allow User Sign-Ups
  - [x] Allow use of upstream OAuth providers for login
    - [x] Support Discord
    - [x] Support GitHub
    - [ ] Support Steam
    - [ ] Require authentication to add new provider to existing account (keyed on email)
  - [x] Allow changing user passwords
  - [ ] Show Audit Log of Actions Taken
  - [ ] Support for TOTP authentication
  - [ ] Support for U2F/FIDO2/WebAuthn authentication
  - [ ] Role management (banned, developer, admin)
- Character Management
  - [x] Add Character by Lodestone ID
  - [ ] Add Character by Name/Server
  - [x] Generate Verification Codes for Character
  - [x] Check Profiles for Verification Codes
  - [ ] Guided walk-through for character addition (Lodestone link, verification steps)
    - [ ] Auto-refreshing modal to test for verification status
- Application Management
  - [x] Allow creation of applications
  - [x] Allow regeneration of `client_secret` by developer
  - [ ] Apps can be restricted to certain users
  - [x] Allow choosing from restricted scope list
  - [ ] Apps can declare privileged scopes as "mandatory"
  - [x] Multiple apps can share a single pairwise token
    - [ ] Developers can self-configure pairwise token management (?)
  - [ ] Developer metrics system to view authentication counts and other stats
- Developer Teams
  - [ ] Allow creation of teams which may own applications
  - [ ] Team roles
    - [ ] Owner - can add/remove team members. Restricted to one.
    - [ ] Developer - can create/edit/delete apps, reset app credentials, etc.
    - [ ] User - can use private apps owned by this team
  - [ ] Allow teams to have child teams who inherit developers from parent
- API/OAuth
  - [x] Apps can query for verified character(s)
    - [x] Characters have "entangled IDs" such that different users with the same character do not collide
  - [x] Apps can query for user profile information
    - [x] Apps receive pairwise user IDs to preserve user privacy (???)
  - [x] Apps can receive extended user profile information with `user:email` scope
  - [ ] Apps with certain scopes can create *unverified* characters and see information about them (XIVAuth-in-Dalamud)
  - [ ] Users can block certain scopes like `user:email` during authorization, unless required by app
  - [x] Users can select a single verified character for `character` scope
  - [ ] Users can customize `character:all` scope
    - [ ] Users can select to share some characters/all characters
    - [ ] If additional scopes present, user can share no characters
    - [ ] If `refresh` scope present, user can share all current+future characters, with exceptions
  - [ ] Applications can use `{resource}:jwt` scopes to request attestations (either character ownership or user auth)
    - [ ] API supports passing in a secondary `client_id` for pairwise key consistency (??)
    - [ ] Applications can self-verify via RSA signature against known public key
  - [ ] OAuth API supports `authorization_code` grant type for web services
  - [x] OAuth API supports `device_code` for desktop apps or Dalamud
    - [ ] Device Code supports scope restrictions
  - [ ] OpenID support
- Admin Features/System Maintenance
  - [ ] Allow granting restricted scopes to applications
  - [ ] Allow support actions like password reset, MFA reset, character (un)verification
  - [ ] Allow marking characters as "restricted" and blocking registration attempts for them (VIPs)
  - [x] Sidekiq-backed cron system
    - [ ] Update saved Lodestone profiles periodically
    - [ ] Delete unverified characters after n days
    - [ ] Delete expired oauth credentials after n days
