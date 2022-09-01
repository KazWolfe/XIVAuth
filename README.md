# XIVAuth

XIVAuth is a service designed to make authenticating characters in Final Fantasy XIV simple, clean, and convenient.

## Features

* OAuth Provider allows other sites to leverage XIVAuth for signin
  * Three modes: Single Character, User, Multi-Character - dev-selectable
    * Single Character: Default mode, info for *only* the authenticated character is returned, no user data.
      * Useful for apps that want to authenticate against a specific character for something.
      * Can only be used with verified characters.
    * User: Info for *only* the authenticate a specific user.
      * Useful for apps that want to authenticate against a player, esp. for deduplication.
      * WILL expose if user has verified characters, but not how many.
      * Can be used if user doesn't have verified characters.
    * Multi-Character: Hybrid of above. Returns user + one or more associated characters.
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
