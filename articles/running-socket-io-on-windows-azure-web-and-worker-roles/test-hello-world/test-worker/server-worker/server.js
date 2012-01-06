var port = process.env.port || 81;

var app = require('http').createServer(handler)
  , io = require('socket.io').listen(app)

app.listen(port);
console.log('socket.io server started on port: ' + port);

function handler (req, res) {
  res.writeHead(200);
  res.end('socket.io server started on port: ' + port);
}

io.sockets.on('connection', function (socket) {
  socket.emit('sayHello', { message: 'Hello back!' });
});
