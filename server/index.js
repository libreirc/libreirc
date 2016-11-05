// @flow

const path = require('path');
const os = require('os');

const Koa = require('koa');
const send = require('koa-send');
const koaRouter = require('koa-router');


const port /*: number */ = parseInt(process.argv[2]) || 4321;
const app = new Koa();
const router = koaRouter();

const publicDirectory /*: string */ = path.join(__dirname, 'public');

router.get('/', async ctx => {
  await send(ctx, 'index.html', { root: publicDirectory });
});
router.get('*', async ctx => {
  await send(ctx, ctx.path, { root: publicDirectory });
});
app.use(router.routes());

app.listen(port);

console.log('OpenIRC server is available on:');
const ifaces = os.networkInterfaces();
for (let device of Object.keys(ifaces)) {
  for (let details of ifaces[device]) {
    if (details.family === 'IPv4') {
      console.log(`  http://${ details.address }:${ port }`);
    }
  }
}
