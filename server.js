// Just a basic server setup for this site
var Stack = require('stack'),
    Creationix = require('creationix'),
    Http = require('http');

var port = process.env.port || 1337;
	
Http.createServer(Stack(
  Creationix.log(),
  require('wheat')(process.env.JOYENT ? process.env.HOME + "/howtonode" : __dirname)
)).listen(port);
