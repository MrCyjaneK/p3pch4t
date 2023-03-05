# Single Server Multiple Destination Chats

<!-- SSMDC -->

connstring will look like this:

i2p://xxx.b32.i2p/ssmdc.v1/uniqueId

client will then send requests to:

xxx.b32.i2p/ssmdc.v1/uniqueId/....

instead of xxx.b32.i2p/... (for example xxx.b32.i2p/ssmdc.v1/uniqueId/core/selfpgp instead of just xxx.b32.i2p/core/selfpgp).

Obviously nothing stops people from deploying a group server on a root path, but this is out of the scope for the reference implementation as it would kill the ability to use the client. Maybe I'll do it in the Go implementation?


### General idea

The idea is to have a single device that is always on and connected to i2p that will act as a group server, it will handle things such as:

 - Invitations
 - Own PGP key, one per group.
 - Relaying messages (once message reaches the server it will get broadcasted to other users).
 - Group server will take care of remembering user's nicknames, bans and participant list
 - Should contain a couple of commands that will make it easier to maintain the group
 - Permission system.

There are many pros to this solution, one of which is ease of use when deploying such kind of thing, imo this will be the recommended way for larger groups - but this also have several cons, when server will go offline nobody will be able to communicate with server and with any of the participants.