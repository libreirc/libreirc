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
