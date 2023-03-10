# reactions.v1

Even though we currently only have single user chats implemented (yes, SSMDC.v1 is also a single user chat). We need to think of reaction as of something that may come from multiple users (just as currently an Event can have multiple destinations).

Reactions length will not be limited, but visible part will be limited to 16 characters (.substr(0,16).split(' ')[0]) - to allow bots in future to reply to some specyfic message, or allow some other useful things.

Why no limit?
```plain
> "😶‍🌫️".length
< 6
> "🙂".length
< 2
```