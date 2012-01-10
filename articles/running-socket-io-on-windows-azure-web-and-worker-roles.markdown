Title: Running socket.io on Windows Azure Web and Worker roles
Author: Mariano Vazquez
Date: Mon Jan 09 2012 11:30:01 GMT-0300
Node: v0.6.6

In this article, I'm going to show you how to configure a Node.js server using two ways Windows Azure provides to host your applications, Web and Worker roles. 

Both approaches works with nearly the same code (with a minor tweak to disable Web Sockets in Web roles), which leads the decision on what to choose depending solely on your own requirements and needs.

I've started from the basic 'Hello World' template created by the [Windows Azure Powershell for Node.js cmdlets](https://www.windowsazure.com/en-us/develop/nodejs/) to develop both roles, with the proper modifications to send messages via `socket.io`. Additionally, I've created a [client](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/running-socket-io-on-windows-azure-web-and-worker-roles/client.zip) application you can use to test that everything is in place, it simply opens a connection to the server (either a Web or a Worker role) and shows the messages it receives.

## The Client code

Below is the javascript code for the client. Note that I clean the label that stores the message every time I click the button. This way you can easily tell how much it takes the whole emit-receive flow to complete. 
Remember to to specify the server URL and port.

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

You should expect to receive this result:

![](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/running-socket-io-on-windows-azure-web-and-worker-roles/client-on-worker.png?raw=true)

Now, let's implement the server code.

## Running on a Windows Azure Worker role

The Worker role approach is fairly straightforward. You just need to install the `socket.io` module on the role and replace the code in the server.js file with the following:


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

I've deployed the server in Azure and tested it with a with IE and Chrome. One thing to notice is that IE doesn't support `Web Sockets`, while Chrome does.

![](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/running-socket-io-on-windows-azure-web-and-worker-roles/ie-client-worker.png?raw=true)

![](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/running-socket-io-on-windows-azure-web-and-worker-roles/chrome-client-worker.png?raw=true)


## Running on a Windows Azure Web role

If you use this approach you should disable Web Sockets. This is because Web roles run in a pre-configured IIS7; and IIS doesn't support web sockets yet. Override the transport mechanism to use, for instance, `xhr-polling` with a 10 sec. polling duration. No matter which client tries to connect to the server, that will be the transport method used. 

Replace the server.js file with the same code you used for in the worker role approach, but add the following lines at the end of the file:

**server.js**

	...
	io.configure(function () { 
	  io.set("transports", ["xhr-polling"]); 
	  io.set("polling duration", 10); 
	});

If you leave it this way, you will experience some initial delay in browsers that support Web Sockets (like Chrome), because they will try to use Web Sockets as first option, and when it fails, use the next transport method in the list (by default, `socket.io` is configured to use the following transport methods, in this order: websocket, htmlfile, xhr-polling and jsonp-polling).

![](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/running-socket-io-on-windows-azure-web-and-worker-roles/chrome-client-webrole.png?raw=true)

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

* You can use nearly the same code in your server.js file in a Web and a Worker role.
* Each socket.io connection will use different transport method, dependending what the browser supports.
* If you use a Web role, remember to disable Web Sockets, as IIS currently doesn't support this transport method.
* You can use a single transport method for all clients, or an array of supported methods.


