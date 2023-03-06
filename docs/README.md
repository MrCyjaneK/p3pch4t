# How does it work?

There are only two important endpoints that exist, one is used to get the handshake of `/core/selfpgp` it contains plaintext PGP key that is used to later on encrypt every event that is being sent to the endpoint `/core/event`

In this document I won't get too deep into how we can use multiple transport protocols (for example tor, plain http and others. Such things may be useful in future to release less anonymous version of this app to allow for example more ). 

### Starting a conversation

Let's assume that we have Alice and Bob, Alice has Bob's `connstring` [^1], Bob doesn't know Alice and decides to add her as contact.

Bob is sending request to Alice`/core/selfpgp` and verifies that served pgp key is correct [^2]

Alice still doesn't know who's Bob, so Bob needs to send `introduce.v1` event.

Bob is sending event like this to Alice`/core/event`

```json
{
    "name": "Bob",
    "connstring": "i2p://bob",
    "pgp": "---- BEGIN PUBLIC KEY ...."
}
```

Entire event is getting signed with Bob's key (to make sure that Bob sent the event) and encrypted with Alice's key (to make sure that nobody can read the message).

Alice have received the event, and added Bob as contact, Alice is not required to do `/core/selfpgp` on Bob because Bob have already sent `introduce.v1` event and it contained Bob's public key.

Now Alice and Bob can safely exchange other events, such as `text.v1` to send messages to eachother.

## Why is it....

Taking so long to send a message for the first time?

Add a new contact?

Fetch contact's name?

I2p is working best when it's a long lived process, because then it can create tunnels, and meet other peers on the network. From what I've seen ~15minutes is the average time after which you can easily contact most of the peers without significant delays.

## Questions?

Feel free to open Issues for discussion - or even better join the Global Party group on p3pch4t! (Link in README)

[^1]: connstring, contact url - string that is used to identify users on the network. (In future versions connstring will contain publickey fingerprint so it will make sure that no mitm attack can happen)

[^2]: `/core/selfpgp` is being transacted over plaintext, but currently you do not need to worry about it as i2p ensures encryption even of things that are 'plaintext'.