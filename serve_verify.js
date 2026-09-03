// Throwaway verification server for the release build. Delete after use.
const http = require('http');
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, 'build', 'web');
const types = {
  '.html': 'text/html', '.js': 'application/javascript', '.mjs': 'application/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.bin': 'application/octet-stream', '.ico': 'image/x-icon', '.svg': 'image/svg+xml', '.css': 'text/css',
};
http.createServer((req, res) => {
  let url = decodeURIComponent(req.url.split('?')[0]);
  let file = path.join(root, url === '/' ? 'index.html' : url);
  if (!file.startsWith(root)) { res.writeHead(403); return res.end(); }
  fs.readFile(file, (err, data) => {
    if (err) {
      if (!path.extname(url)) {
        fs.readFile(path.join(root, 'index.html'), (e2, d2) => {
          if (e2) { res.writeHead(404); res.end(); }
          else { res.writeHead(200, { 'Content-Type': 'text/html' }); res.end(d2); }
        });
      } else { res.writeHead(404); res.end(); }
    } else {
      res.writeHead(200, { 'Content-Type': types[path.extname(file).toLowerCase()] || 'application/octet-stream' });
      res.end(data);
    }
  });
}).listen(18080, '127.0.0.1', () => console.log('serving build/web on http://127.0.0.1:18080'));