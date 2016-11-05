OpenIRC
========
IRC for everyone!

### Project Goal
Making open source alternative of [IRCCloud]

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
yarn build          # Build everything in production mode (flow + babel)

yarn watch          # Run babel in watch mode
yarn start [port]   # Start the server. Default port is 4321
```

### Directory structure
```bash
# Client side codes
▾ client/
    .flowconfig
  ▸ node_modules/
  ▸ src/                # Client-side assets (js, css, ...)
    package.json        # Client-side libraries
    webpack.config.js

# Server side codes
▾ server/
    .babelrc
    .flowconfig
  ▸ dist/               # Build results of server-side codes
  ▸ node_modules/
  ▾ public/             # Files that will be statically served
    ▸ build/            # Build results of client-side assets
      ...
      index.html
  ▸ src/                # Server-side codes (node.js)
    package.json        # Server-side libraries
```

--------

[GNU AGPL 3.0 License](LICENSE.md)

[IRCCloud]: https://www.irccloud.com/
