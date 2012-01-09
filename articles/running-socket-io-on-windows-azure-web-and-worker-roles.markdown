Title: Running socket.io on Windows Azure Web and Worker roles
Author: Mariano Vazquez
Date: Mon Jan 09 2012 11:30:01 GMT-0300
Node: v0.6.6

While setting up your Node.js server, you may notice that Windows Azure provides two different flavors to host your applications, Web and Worker roles.

 Which one you choose depends solely on your own requirements and needs (web roles are the best choice to host web applications, while worker roles are suited for long-running, asynchronous processes).

In this article I'm going to show you how to configure a Node.js server using both approaches. I'm starting from the basic 'Hello World' template created by the [Windows Azure Powershell for Node.js cmdlets](https://www.windowsazure.com/en-us/develop/nodejs/), with the proper modifications to send the messages via socket.io. Also, I've created a client application that opens a connection to the server (either in a web or a worker role) and shows the messages received from it.

## The client

Below is the javascript code of hte client. Notice that I clean the label every time I click the button. This way you can tell how much it takes the whole process to complete.

	<script type="text/javascript">
        var socket;
        $(document).ready(function () {
            $("#startButton").click(function () {
                $("#returnMessageLabel").empty();
                if (!socket) {
                    socket = io.connect("http://localhost:81/");
                    socket.on('helloBack', function (data) {
                        $("#returnMessageLabel").text(data.message);
                    });
                }
                socket.emit('sendMessage', { message: 'Hello there!' });
            });
        });  
    </script>

Now, let's see the server code.

## Running on a Windows Azure Worker role

The worker role approach is pretty straightforward. You just need to install the socket.io module on the role and replace the code in the server.js file with the following.


**server.js**

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

If you run both client and server you will get the following result.

![Alt text](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/running-socket-io-on-windows-azure-web-and-worker-roles/client-on-worker.png?raw=true "Hello World sample using Worker Role as Server")

> Note: if you want to deploy the app, I recommend you follow [this](http://nodeblog.cloudapp.net/startup-task-to-run-npm-in-azure) approach to install npm and avoid deploying node modules.

## Running on a Windows Azure Web role

If you use this approach you need to disable Web Sockets. This is because web roles run in a pre-configured IIS7, and IIS doesn't support web sockets yet. 

You just need to override the transport mechanism to use ´xhr-polling´ with a 10 sec polling duration, no matter which client tries to connect to the server. Replace the server.js file with the same code you used for the worker role, but add the following lines at the end of the file:

*server.js*

	io.configure(function () { 
	  io.set("transports", ["xhr-polling"]); 
	  io.set("polling duration", 10); 
	});

You can leave it as it is, although you will experience some initial delay in Chrome or FF, because they will try to use Web Sockets as first option, and then degrade to the next transport method. Other approach could be setting an array of allowed methods, like the following:

*server.js*

	io.configure(function () { 
	  io.set('transports', [
	  	'xhr-polling'
	  , 'jsonp-polling'
	  , 'htmlfile'
	  ]);
	  io.set("polling duration", 10); 
	});


