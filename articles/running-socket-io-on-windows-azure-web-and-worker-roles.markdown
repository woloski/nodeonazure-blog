Title: Running socket.io on Windows Azure Web and Worker roles
Author: Mariano Vazquez
Date: Mon Jan 09 2012 11:30:01 GMT-0300
Node: v0.6.6

In this article, I'm going to show you how to configure a Node.js server using both ways Windows Azure provides to host your applications, Web and Worker roles. 

Hopefully, both approaches works with the same code (with a minor tweak to disable Web Sockets in Web roles), which leads the decision on what to choose depending solely on your own requirements and needs (i.e. web roles are the best choice to host web applications, while worker roles are suited for long-running, asynchronous processes).

To implement both approaches, I've started' from the basic 'Hello World' template created by the [Windows Azure Powershell for Node.js cmdlets](https://www.windowsazure.com/en-us/develop/nodejs/), with the proper modifications to send messages via `socket.io`. Also, I've created a client application that opens a connection to the server (either a Web or a Worker role) and shows the messages it receives.

## The Client code

Below is the javascript code for the client. Note that I clean the label that stores the message every time I click the button. This way you can easily tell how much it takes the whole flow to complete.

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

Now, let's implement the server code.

## Running on a Windows Azure Worker role

The worker role approach is fairly straightforward. You just need to install the socket.io module on the role and replace the code in the server.js file with the following.


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

![](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/running-socket-io-on-windows-azure-web-and-worker-roles/client-on-worker.png?raw=true "Hello World sample using Worker Role as Server")


## Running on a Windows Azure Web role

If you use this approach you need to disable Web Sockets. This is because Web roles run in a pre-configured IIS7, and IIS doesn't support web sockets yet. 

You just need to override the transport mechanism to use, for instance, `xhr-polling` with a 10 sec. polling duration. No matter which client tries to connect to the server, this will be the transport method used. Replace the server.js file with the same code you used for in the worker role approach, but add the following lines at the end of the file:

**server.js**

	...
	io.configure(function () { 
	  io.set("transports", ["xhr-polling"]); 
	  io.set("polling duration", 10); 
	});

If you don't add the lines above you will experience some initial delay in browser that supports Web Sockets (like Chrome) because they will try to use this mechanism as first option, and then **degrade** to the next transport method in the list. Other approach could be setting an array of allowed methods (instead of only one), like the following:

**server.js**

	io.configure(function () { 
	  io.set('transports', [
	  	'xhr-polling'
	  , 'jsonp-polling'
	  , 'htmlfile'
	  ]);
	  io.set("polling duration", 10); 
	});

## Conclusion

* You can use nearly the same code in your server.js file in a Web and a Worker role.
* If you use a Web Role, remember to disable Web Sockets, as IIS currently doesn't support this transport method.
* You can use a single transport method for all clients, or an array of supported methods.


