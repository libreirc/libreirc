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

cargo run     # Start a server

# Start the server in production mode
cargo run --release
```
