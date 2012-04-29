Title: Creating a collaborative realtime markdown editor - the "Google Docs" for Markdown
Author: Matias Woloski
Date: Thu Apr 29 2012 12:00:00 GMT-0300
Node: v0.6.6

Markdown is getting a lot of traction in the development community. For instance, I am using it to edit the articles of this blog, to edit the README on github, to write documentation, in a CMS, in a wiki, in a [jekyll](https://github.com/mojombo/jekyll)-based site, in [tumblr](http://tumblr.com) etc. We like it because of its lightweight nature that makes you focus on the content instead of the form.

This article explains how MarkdownR <http://markdownr.cloudapp.net/> works and it is separated in the following parts:

* Why implementing a collaborative realtime markdown editor?
* Finding the right building blocks
* Building the v0.1
* Adding support for copy paste in Google Chrome
* Import/export from Windows Azure blob storage
* Running on the Windows Azure cloud
* Implementing auto-save persistance with CouchDB
* Adding support for authentication with everyauth and Windows Azure Access Control Service

## Why writing a collaborative realtime markdown editor?

Honestly, because I find Markdown a great syntax to crank out text with just the right amount of formatting. And since it is just text, it makes really easy to apply a merge algorithm on the server. So it's a great learning experience.

On the other hand I wanted something where I can:

* Write things collaboratively (like a spec, design doc, meeting minute, etc.)
* Have instant feedback on the markdown you are writing
* Have auto-save

It was important also that

* Works on any modern browser
* Support copy pasting of images right there in the editor (like gmail)
* Could run on the cloud (specifically on Windows Azure)
* Allow importing/exporting the content to somewhere (i.e.: Azure blob storage, Amazon S3, GitHub)

## Finding the right building blocks

First thing was finding the right package. I knew [socket.io](http://socket.io) was going to be part of it, but it was kind of low level. I thought someone should have done something on top of socket.io. Then I've found [etherpad](https://github.com/ether/pad) which looks really cool but it was too heavyweight (requires an incredible stack of technology). Looking for an alternative that could run on node.js I've came across [etherpad-lite](https://github.com/pita/etherpad-lite). It looked promising but I've found it more like "add etherpad to your website" rather than a "building block to create realtime editors". Kept looking and found [share.js](http://sharejs.org). This was more inline with what I wanted. The demo on its homepage bought me in: a collaborative realtime textarea editing :)

![](http://markdownr.blob.core.windows.net/images/4740232956.png)

How it works from [share.js](http://sharejs.org) website:

> As you edit the text area at the top of this page, ShareJS generates operations. Operations are like mini commits to the document. (Eg, `insert:'hi'`, `position:50`.)
> Like subversion, the server has a version number. If multiple users submit an operation at the same version, one of the edits is applied directly and the other user’s edit is automatically transformed by the server and then applied. Transforming is a bit like a git rebase operation.
> In your browser, your edits are visible immediately. Edits from other people get transformed on top of yours. Unlike normal SCM systems, the algorithm is very careful to make sure that everyone ends up with the same document, no matter what order the operations are actually applied in. This allows the whole update & commit stuff to happen completely automatically, in realtime. There are no conflict markers or any of that jazz.

## Building the v0.1
After doing a couple of tests we were satisfied with share.js. So we went ahead and created the barebone functionallity taken from share.js samples.

The following code will listen `GET` requests on `/something` an create/open a document with that name


	app.get('/:docName', function(req, res, next) {
		var docName = req.params.docName;
		editor.openDocument(docName, app.model, res, next);
	});


The code required to open a document is something like this: 

	openDocument: function(docName, model, res) {
		var self = this;
		return model.getSnapshot(docName, function(error, data) {
			if (error === 'Document does not exist') {
			  return model.create(docName, 'text', function() {
				var content = defaultContent(docName);
				return model.applyOp(docName, { op: [ { i: content, p: 0 } ], v: 0 }, function() {
					return self.render(content, docName, res);
				});
			  });
			} else {
				return self.render(data.snapshot, docName, res);
			}
		});
	},

This code is pretty simple:

* It wil call the `getSnapshot` function from sharejs sending the document name as a parameter. 
* The library will search the snapshot on the configured persistance (default in memory) and if it is not there it will throw a 'Document does not exist' error. 
* If it doesnt exist we are creating a new one (`model.create`) and applying a default content with `mode.applyOp`).
* It will call the `render` function of the `Editor` to finally render the markdown (either the existing snapshot or the new content)

The rendering is using [mustache templates](http://mustache.github.com/) and [Showdown](https://github.com/coreyti/showdown)

	render: function(content, docName, res) {
		var markdown = (new Showdown()).makeHtml(content);
		var data = {
			content: content,
			markdown: markdown,
			docName: docName,
			user: this.userName,
			isUserSet: this.userName !== undefined
		}
		var html = Mustache.to_html(template, data);
		res.writeHead(200, {'content-type': 'text/html'});
		res.end(html);
	},

The model gets created when you attach sharejs to the express app

	sharejs.server.attach(app, settings.options);

On the client side we are using the awesome [ace editor](https://github.com/ajaxorg/ace) with the textmate theme. Notice how the sharejs connection is opened and then we listen the `open` event and attach the ace editor to the sharejs doc using `attache_ace`. Then we setup a listener for `change` to call the render function which will generate the markdown everytime something changes on the `doc` (on any connected client). 

	var converter = new Showdown.converter();
	var view = document.getElementById('view');

	var editor = ace.edit("editor");
	editor.setReadOnly(true);
	editor.session.setUseWrapMode(true);
	editor.setShowPrintMargin(false);

	var connection = new sharejs.Connection('/channel');
	        
	connection.open('{{{docName}}}', function(error, doc) {
		if (error) {
		  console.error(error);
		  return;
		}
	    
		doc.attach_ace(editor);
		editor.setTheme("ace/theme/textmate");
		editor.getSession().setMode(new(require("ace/mode/markdown").Mode)());
		editor.setReadOnly(false);

		var render = function() {
		  view.innerHTML = converter.makeHtml(doc.snapshot);
		};

		window.doc = doc;

		render();
		doc.on('change', render);
	});

## Adding support for copy paste in Google Chrome

One of the things that I find annoying in markdown editors are support for images. You need to have some plugin that uploads the image somewhere and then handcraft the markdown syntax in your editor. I wanted something simpler like what Gmail does. Copy paste straight to the browser!

After some search on google we've found what we were looking for: the `paste` event

	event.addListener(text, "paste", function(e) { ... });

If you are interested in the code [you can see the details at line 7263 of ace.js](https://github.com/southworksinc/markdownR/blob/master/src/public/ace/ace.js#L7263). We wanted to contribute this back to ace but didn't find the way to do it, so probably we should move it out from there or create an addon like model.

The paste event will have in the clipboardData the base64 representation of the image and the content type. So the rest is simple, make an AJAX request to the upload endpoint and save to a container in Windows Azure blob storage

	saveStreamToBlob: function(fileName, dataURL, model, res) {
		var self = this;
		var container = 'images';
		var filePath = self.tempPath + fileName;
		fs.writeFile(filePath, dataURL, 'base64', function (err) {
			...
				self.blobService.createContainerIfNotExists(container, function(err){
					if(err){
						console.log(err);
					}
				});
				var readStream = fs.createReadStream(filePath);
				var stat = fs.statSync(filePath);
				self.blobService.uploadImageToBlob(container, fileName, readStream, stat.size, function(err, result){
					if(err) {
						console.log(err);
					}
					else {
						fs.unlink(filePath);
						res.send(result);
					}
				});
			}
		});
	}

Here is how it works from the browser:

![](http://markdownr.blob.core.windows.net/images/copy-paste.gif)

## Import/export from Windows Azure blob storage

Before implementing autosave persistance we wanted to have a way to save the docs somewhere and since we have a Windows Azure subscription we implemented the functionallity to open and save to blob storage.

Implementing this on the server side was easy. It actually took more implementing the client side (the file explorer).

Interacting with the Windows Azure storage is straightforward thanks to the `azure` package. If you want to see some code you can browse the [`azureBlobService.js`](https://github.com/southworksinc/markdownR/blob/master/src/lib/azureBlobService.js) on [GitHub](https://github.com/southworksinc/markdownR/blob/master/src/lib/azureBlobService.js). This is an example of listing the containers from the account.

	getContainerNames: function(callback){
		var self = this;
		self.blobService.listContainers(function(err, result){
			if(!err){
				var names = obtainPropertyValue(result, 'name');
				callback(null, names);
			}
			else
				callback(err, null);
		});
	},

We used the [jQueryFileTree](http://labs.abeautifulsite.net/archived/jquery-fileTree/demo/) plugin to render the explorer-like view for blob storage.

![](http://markdownr.blob.core.windows.net/images/616855566.png)

## Running on the cloud

We could run this on any cloud actually but we chose [Windows Azure](https://www.windowsazure.com/en-us/develop/nodejs/) because:

* we are familiar with it, 
* we have a subscription, 
* we want the low latency from blob storage
* it gives us a bare bone VM where we could run **any** version of node and also we could use websockets easily.

When we started working on this share.js was on 0.4.0 and was using [socket.io](http://socket.io). Hence we chose to host this on a [worker role](https://www.windowsazure.com/en-us/home/features/compute/) so that we could make use of websockets (since a web role running IIS does not support that yet). However, the 0.5.0pre version removed socket.io as the default transport and implemented [browserchannel](https://github.com/josephg/node-browserchannel) that does long-polling so we decided to move to a web role that runs iisnode and provide a better story on Azure in general (logging, lifecycle management among others). 

![](http://markdownr.blob.core.windows.net/images/3893854937.png)

This is running on an **extra small** instance which costs **$15 usd / month**

You will find all the azure-related deploy stuff here
<https://github.com/southworksinc/markdownR/tree/master/azure-deploy>

## Implementing auto-save persistance with CouchDB

CouchDB is one of the out of the box persistance options provided by sharejs. The other options were Redis and Postgre. We chose CouchDB simply because [Cloudant](http://cloudant.com) provides a 250MB database for free and the free option on Redis providers were only 5mb. Even though there is some latency, the save process is not noticeable for the user and the performance is quite good. But if I were to run this for real, I would probably spin up a couple of Linux VM on Azure running Redis.

This is how you configure sharejs to run on CouchDB

	var options = {
	  db: {
			type: 'couchdb',
			uri: 'https://yourdb:yourpwd@markdownr.cloudant.com/markdownr/'
	  },
	  port: port
	};

	sharejs.server.attach(app, options);

The CouchDB store will require the creation of a map process. You will find a setup_couch node program that will do that for you under `node_modules\share\bin\setup_couch`.

Here are some stats on CouchDB after running <http://markdownr.cloudapp.net> a month or so.

![](http://markdownr.blob.core.windows.net/images/6087871983.png)

Even though there are tons of documents, we only have used 7MB which is not a lot. Sharejs will store each operation as a separate document. In this case, this operations says: { i: ript, p: 12210  } which means 'insert' 'ript' on 'position' '12210'. Also you can see the version of the document: 6337. That means that the document was updated 6337 times already, and each of those was an operation

![](http://markdownr.blob.core.windows.net/images/4144430340.png)


## Adding support for authentication with Windows Azure Access Control Service

Finall, we wanted to deploy MarkdownR to be used across the company. Since we already have federated identity of all the internal apps, this should not be the exception. MarkdownR does not support security per document for now (hopefully in the future), so for now we just protected the full app with a token. Anyone that logs in with a Southworks identity could use it. It's using Southworks Active Directory (via ADFS) on-premises and MarkdownR is hosted on the cloud. You can see the experience by browsing <http://markdownr.southworksinc.com>.

Adding federated identity was simple using the [Windows Azure Access Control Service][]. It was basically applying the concepts discussed in the [Using Windows Azure Access Control Service (ACS) from a node express app](http://nodeblog.cloudapp.net/using-windows-azure-access-control-service-acs-from-a-node-app) article.

Here are the important pieces of code. First thing is to configure [everyauth][]. This module supports various authentication methods (OAuth, OpenID, Facebook, Google, etc.) and we implemented support for ACS. This piece of code shows the configuration of everyauth and ACS.

	if (settings.auth.enabled) {
		var everyauth = require('everyauth');

		everyauth.debug = false;  // true= if you want to see the output of the steps

		everyauth.azureacs
		  .identityProviderUrl(settings.auth.identityProviderUrl)
		  .entryPath('/auth/azureacs')
		  .callbackPath('/auth/azureacs/callback')
		  .signingKey(settings.auth.signingKey)
		  .realm(settings.auth.realm)
		  .homeRealm(settings.auth.homeRealm || '') // if you want to use a default idp (like google/liveid)
		  .tokenFormat('swt')  // only swt supported for now
		  .findOrCreateUser( function (session, acsUser) {
		     // you could enrich the "user" entity by storing/fetching the user from a db
		    return null;
		  })
		  .redirectPath('/');

		everyauth.everymodule.logoutRedirectPath('/bye');
	}

The next thing is to configure everyauth as part of the express pipeline. 

	app.configure(function(){
	  app.set('views', __dirname + '/views');
	  ...
	  app.use(express.session({ secret: "markdownr editor" }));
	  
	  if (settings.auth.enabled) {
		app.use(everyauth.middleware());
		app.use(denyAnonymous(['/bye']));  // deny anonymous users to all routes
		everyauth.helpExpress(app);
	  }

	  app.use(app.router);
	});

And finally, we define another interceptor in the pipeline to implement the "deny anonymous" pattern: unless the user is authenticated, every url will expect authenticated users. There is an exclude array where you can specify urls that are public (allow ananymous).

	function denyAnonymous(exclude) {
		return function(req, res, next) {
		    if (exclude && exclude.indexOf(req.url) >= 0)
		    	next();
		    else {
		    	if (typeof(req.session.auth) == 'undefined' || !req.session.auth.loggedIn) {
			    	req.session.originalurl = req.url;
			    	res.redirect('/auth/azureacs');
			    	res.end();
			    } else {
			    	var originalUrl = req.session.originalurl;
			    	if (originalUrl !== null && originalUrl !== '') {
			    		req.session.originalurl = '';
			    		res.redirect(originalUrl);
			    	} else {
			    		next();	    		
			    	}
			    }	
		    } 
	  	}
	}

## Conclusion

It's amazing what we can do with node. There are almost 10,000 packages that can be used as building blocks to create things like this. Not only that, but it's also very easy to have it working online, in this case using Windows Azure and Cloudant CouchDB.

In terms of roadmap, here are some of the things that I would like MarkdownR to support in the future:

* Security at document level (invite workflow)
* Caret and user tracking (who's online on a document and where is the cursor)
* Embedded editor (to be used in other websites)
* Support for documents mash up
* Discoverability of documents

You are invited to collaborate: <https://github.com/southworksinc/markdownR>

[Windows Azure Access Control Service]: https://www.windowsazure.com/en-us/home/tour/access-control/
[everyauth]: https://github.com/bnoguchi/everyauth
