Title: Running socket.io on Windows Azure Web and Worker roles
Author: Mariano Vazquez
Date: Tue Jan 10 2012 15:49:01 GMT-0300
Node: v0.6.6

In this article, we are going to review how to configure a Node.js + [socket.io][] server both inside a web and a worker roles (if you are not familiar with what a web and worker role is, read the following [MSDN article](http://msdn.microsoft.com/en-us/library/gg432976.aspx)).

Both approaches work with nearly the same code (with a minor tweak to disable WebSockets in Web roles), which leads the decision on what to choose depending solely on your own requirements and needs.

You start from the basic 'Hello World' template created by the [Windows Azure Powershell for Node.js cmdlets](https://www.windowsazure.com/en-us/develop/nodejs/) to develop both roles, with the proper modifications to send messages via [socket.io][]. We have created a [client](/running-socket-io-on-windows-azure-web-and-worker-roles/client.zip) application you can use to test that everything is in place; it simply opens a connection to the server (either a Web or a Worker role) and shows the messages it receives.

## Connecting to a socket.io server

Below is the javascript code for a very simple client. Notice that it is cleaning the label that stores the message every time you click the button. This way you can easily tell how much it takes the whole emit-receive flow to complete. 
Remember to specify the server URL and port.

	<script type="text/javascript">
        var socket;
        $(document).ready(function () {
            $("#startButton").click(function () {
                $("#returnMessageLabel").empty();
                if (!socket) {
                    socket = io.connect("http://<YOUR-SERVER-URL>:<YOUR-PORT>/");
                    socket.on('helloBack', function (data) {
                        $("#returnMessageLabel").text(data.message);
                    });
                }
                socket.emit('sendMessage', { message: 'Hello there!' });
            });
        });  
    </script>

You should get back something like this:

![](/running-socket-io-on-windows-azure-web-and-worker-roles/client-result.png)

Now, let's look at the server code.

## Running on a Windows Azure Worker role

The Worker role approach is fairly straightforward. You just need to install the [socket.io][] module on the role and replace the code in the server.js file with the following:

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

There is nothing specific to Windows Azure as you can see.
We deployed this to an extra small instance on Windows Azure and tested it with Internet Explorer 9 and Google Chrome. 
 
![](/running-socket-io-on-windows-azure-web-and-worker-roles/ie-client-worker.png)

![](/running-socket-io-on-windows-azure-web-and-worker-roles/chrome-client-worker.png)

Since Internet Explorer 9 does not have support for `WebSockets` (IE10 will), it will *degrage* the connection to `xhr-polling`. By default, [socket.io][] is configured to use the following transports (in this order): *websocket*, *htmlfile*, *xhr-polling* and *jsonp-polling*

## Running on a Windows Azure Web role

If you host [socket.io][] in a web role, you will have to disable the WebSockets transport on the server. This is because Web roles run in a pre-configured IIS7, and IIS doesn't support web sockets yet. Override the transport mechanism to use, for instance, `xhr-polling` with a 10 sec. polling duration. No matter which client tries to connect to the server, that will be the transport method used. 

To configure the transport, add the dollowing snippet to the `server.js` file with the same code you used for in the worker role approach, but add the following lines at the end of the file:

**server.js**

	...
	io.configure(function () { 
	  io.set("transports", ["xhr-polling"]); 
	  io.set("polling duration", 10); 
	});

If you don't add this fix, you will experience some initial delay in browsers that support WebSockets (like Chrome). That delay is generated because it will try to use WebSockets as first option.

![](/running-socket-io-on-windows-azure-web-and-worker-roles/chrome-client-webrole.png)

Alternatively, you could configure an array of allowed methods (instead of one), using the following code:

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

To sum up what we have learnt in this article:

* You can host socket.io in Windows Azure
* It works in both worker and web roles.
* If the browser supports WebSockets it will try that first.
* If you use a Web role, remember to disable WebSockets transport, as IIS currently doesn't support it. 

[socket.io]: http://socket.io

