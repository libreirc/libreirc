OpenIRC
========
IRC for everyone!

### Project Goal
Making open source alternative of [IRCCloud]

### Intructions
```bash
# Building client-side codes
cd client

npm install   # Install dependencies
npm test      # Static type checking (flow)
npm run build # Build everything in production mode (flow + webpack)

npm run watch # Run webpack in watch mode
```
```bash
# Running server
cd server

npm install      # Install dependencies
npm test         # Static type checking (flow)
npm run build    # Build everything in production mode (flow + babel)

npm run watch    # Run babel in watch mode
npm start [port] # Start the server. Default port is 4321
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

[IRCCloud]: https://www.irccloud.com/
