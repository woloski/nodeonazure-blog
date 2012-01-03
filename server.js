// Just a basic server setup for this site
var Stack = require('stack'),
    Creationix = require('creationix'),
    Http = require('http'),
    ChildProcess = require('child_process');


var port = process.env.port || 1337;
console.log(port);
console.log('sssss');
	
Http.createServer(Stack(
  Creationix.log(),
  function handler(req, res, next) {
  // Either handle the request here using `req` and `res`
  // or call `next()` to pass control to next layer
  // any exceptions need to be caught and forwarded to `next(err)`
   if (req.method == 'GET' && req.url == '/hook') {
  		gitExec(['pull'], 'utf8', function (err, text) {
    		res.writeHead(200);
   			res.end('sds');
  		});
   		
   		res.writeHead(200);
   		res.end('OK');
   }
   else 
   		next();
  },
  require('wheat')(process.env.JOYENT ? process.env.HOME + "/howtonode" : __dirname)
  )).listen(port);


function gitExec(commands, encoding, callback) {
  var child = ChildProcess.spawn("git", commands);
  var stdout = [], stderr = [];
  child.stdout.addListener('data', function (text) {
    stdout[stdout.length] = text;
  });
  child.stderr.addListener('data', function (text) {
    stderr[stderr.length] = text;
  });
  child.addListener('exit', function (code) {
    if (code > 0) {
      console.log('stderr' + stderr);
      callback(stderr);
      return;
    }
    callback(null, stdout);
  });
  child.stdin.end();
}