OpenIRC
========
IRC for everyone!

```bash
# Building client-side codes
cd client

npm install   # Install dependencies
npm test      # Static type checking (flow)
npm run build # Build everything in production mode (flow + webpack)

npm start     # Run webpack in watch mode
```
```bash
# Running server
cd server

npm install   # Install dependencies
npm test      # Static type checking (flow)
npm run build # Build everything in production mode (flow + babel)

npm start     # Run babel in watch mode
node .        # Start the server
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
