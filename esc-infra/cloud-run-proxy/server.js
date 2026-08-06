const express = require('express');
const http = require('http');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

const PORT = Number(process.env.PORT || 8080);
const TARGET = process.env.OPENWA_TARGET;

if (!TARGET) {
  throw new Error('OPENWA_TARGET is required');
}

app.get('/_gateway_health', (req, res) => {
  res.json({
    ok: true,
    service: 'esc-whatsapp-gateway',
    target: TARGET
  });
});

const proxy = createProxyMiddleware({
  target: TARGET,
  changeOrigin: true,
  ws: true,
  xfwd: true,
  logLevel: 'warn'
});

app.use('/', proxy);

const server = http.createServer(app);

server.on('upgrade', (req, socket, head) => {
  proxy.upgrade(req, socket, head);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`ESC WhatsApp Gateway proxy listening on ${PORT}, target=${TARGET}`);
});
