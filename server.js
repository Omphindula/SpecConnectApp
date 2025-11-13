// Root entrypoint for Render deployments.
// Some Render service configurations or UI defaults run `node server.js` at the repo root.
// This file simply forwards to the real server implementation in server/zapper_render.

/* eslint-disable @typescript-eslint/no-var-requires */
const path = require('path');
const target = path.join(__dirname, 'server', 'zapper_render', 'server.js');

console.log('Starting app via root server.js ->', target);

try {
  require(target);
} catch (err) {
  console.error('Failed to require backend at', target);
  console.error(err && err.stack ? err.stack : err);
  process.exit(1);
}
