OpenIRC
========
> :heartbeat: IRC Client for everyone!

Making open source alternative of [IRCCloud] is this project's very first goal.
Join our IRC channel if you're interested!

- **#openirc** of [Ozinger IRC network]
- **#openirc-test** of [Ozinger IRC network]

### Intructions
```bash
# Building client-side codes
cd client

yarn                # Install dependencies
yarn test           # Static type checking (flow)
yarn build          # Build everything in production mode (flow + webpack)

yarn watch          # Run webpack in watch mode
```
```bash
# Running server
cd server

yarn                # Install dependencies
yarn test           # Static type checking (flow)

yarn start [port]   # Start the server. Default port is 4321
```

### Directory structure
```bash
# Client side codes
▾ client/
  ▸ src/                # Client-side assets (js, css, ...)
    package.json        # Client-side libraries
    webpack.config.js
    ...

# Server side codes
▾ server/
  ▾ public/             # Files that will be statically served
    ▸ build/            # Build results of client-side assets
      ...
      index.html
  ▸ src/                # Server-side codes (node.js)
    package.json        # Server-side libraries
    ...
```

--------

[GNU AGPL 3.0 License](LICENSE.md)

[Ozinger IRC network]: http://ozinger.org/
[IRCCloud]: https://www.irccloud.com/
