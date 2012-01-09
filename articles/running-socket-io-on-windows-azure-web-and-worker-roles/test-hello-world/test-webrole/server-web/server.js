var port = process.env.port || 81;

var app = require('http').createServer(handler)
  , io = require('socket.io').listen(app)

app.listen(port);
console.log('socket.io server started on port: ' + port + '\n');

function handler (req, res) {
  res.writeHead(200);
  res.end('socket.io server started on port: ' + port + '\n');
}

io.sockets.on('connection', function (socket) {
  console.log('user connected');
  
  socket.on('sendMessage', function(data){
	console.log('user sent the message: ' + data.message + '\n');
	socket.emit('helloBack', { message: 'Hello back!' });
  });
});

io.configure(function () { 
  io.set("transports", ["xhr-polling"]); 
  io.set("polling duration", 10); 
});