var http = require('http');
var port = process.env.port || 1337;

http.createServer(function (req, res) {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    
	res.write("Role Name: " + process.env.RoleName + "\n");
	res.write("Role InstanceID: " + process.env.RoleInstanceID + "\n");
	res.write("Role DeploymentID: " + process.env.RoleDeploymentID + "\n");
	res.write("Is running? " + process.env.IsAvailable + "\n");
	res.write("Custom variable: " + process.env.CustomVariable + "\n");
	
	res.end();
}).listen(port);