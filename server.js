// Just a basic server setup for this site
var Stack = require('stack'),
    Creationix = require('creationix'),
    Http = require('http'),
    ChildProcess = require('child_process');

process.on('uncaughtException', function(err) {
  console.log(err);
});

var port = process.env.port || 1337;
var gitRepoPath = process.env.gitrepoblogpath || __dirname;
	
Http.createServer(Stack(
  Creationix.log(),
  //handleGitHook,
  require('wheat')(gitRepoPath)
  )).listen(port);

console.log('running on port:' + port);
console.log('git repo path:' + gitRepoPath);
