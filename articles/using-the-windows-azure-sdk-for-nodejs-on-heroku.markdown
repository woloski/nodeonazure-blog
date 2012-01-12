Title: Using the Windows Azure SDK for Node.js on Heroku
Author: Juan Pablo Garcia
Date: Wed Jan 11 2012 02:24:35 GMT-0300
Node: v0.4.7

Getting the [Windows Azure SDK for Noje.js](https://github.com/WindowsAzure/azure-sdk-for-Node) running on [Heroku](http://www.heroku.com/) wasn't as easy as we thought, in this article we're going to show you how we can workaround the [Heroku](http://www.heroku.com/) limitation and how to create a simple application that leverages the SDK for listing blob containers. 

## The limitation

As you may know, to get a Node.js application running on [Heroku](http://www.heroku.com/) you need to configure the application to use the Cedar stack as [described here](http://devcenter.heroku.com/articles/node-js). One of the prerequisites is that your application must run on `v0.4.7` but sadly the [Windows Azure SDK for Noje.js](https://github.com/WindowsAzure/azure-sdk-for-Node) npm package requires `>= 0.6.4` as defined in its [package.json](https://github.com/WindowsAzure/azure-sdk-for-node/blob/master/package.json) file, so when [Heroku](http://www.heroku.com/) tries to perform the deployment it fails because of this npm dependency.

We [created an issue on the Github site azure-sdk-for-node](https://github.com/WindowsAzure/azure-sdk-for-node/issues/29) and the team will be changing it soon apparentely. If that's the case, then go straight to the Creating the application section.

## Workaround 1

Basically we've created and published a new npm package by following the steps below:

* Forked the [Windows Azure SDK for Noje.js](https://github.com/WindowsAzure/azure-sdk-for-Node) repository.
* Changed the package name form `azure` to `azure-0.4.7` in the [package.json](https://github.com/WindowsAzure/azure-sdk-for-node/blob/master/package.json) file.

		"name": "azure-0.4.7"

* Modifed the node engine requirement to >= 0.4.7 instead [package.json](https://github.com/WindowsAzure/azure-sdk-for-node/blob/master/package.json) file.

		"engines": { "node": ">= 0.4.7" }

* Finally, we published a the new npm package

		npm publish

The npm `azure-0.4.7` package is public, so instead of the using the official `azure`, you can use this one and it will do the trick! Further on this article you'll see how to use this package.

**DISCLAIMER**: We didn't test all the library's functionality but it seems to be working fine running on `v0.4.7`.

## Workaround 2

There is a [Running Your Own Node.js Version on Heroku](http://blog.superpat.com/2011/11/15/running-your-own-node-js-version-on-heroku/) blog post that describes how to deploy a custom version of Node.js. We didn't use this approach but it should work.

## Creating the application

We'll use the [express](http://expressjs.com/) npm package to create the application, so lets start.

1. Create `package.json` file and configure the `express`, `ejs` and `azure-0.4.7` (our npm tweaked) as project dependencies: 

		{
		  "name": "heroku-azure-storage-sample" ,
		  "version": "0.0.1" ,
		  "dependencies": {
		    "express": "2.5.2",
		    "ejs": "0.6.1",
		    "azure-0.4.7": "0.5.1"
		  }
		}

2. Create a `web.js` file with the following application logic to retrieve the containers for a given account:

		var express	= require('express')
			, azure	= require('azure-0.4.7');
		
		/*
		 * Configuration
		 * ---------------------------------------- */
		var app = express.createServer(express.logger());
		app.register('html', require('ejs'));
		app.set('view engine', 'html');

		/*
		 * Routes
		 * ---------------------------------------- */
		app.get('/', function (req, res) {
			var blobClient = azure.createBlobService(process.env['WAZ_STORAGE_ACCOUNT_NAME'], process.env['WAZ_STORAGE_ACCESS_KEY'])
								  .withFilter(new azure.ExponentialRetryPolicyFilter());
			blobClient.listContainers({}, function(err, result) {
				res.render('index', { layout: false, containers: result });
			});			
		});

		/*
		 * Bootstrap
		 * ---------------------------------------- */
		var port = process.env.PORT || 3000;

		app.listen(port, function () {
			console.log("Listening on " + port);
		});		

3. Configure your account `WAZ_STORAGE_ACCOUNT_NAME` and `WAZ_STORAGE_ACCOUNT_ACCESSS_KEY` environment variables:

	* If you are running Node.js on **Windows**, from the command line:
		
			SET WAZ_STORAGE_ACCOUNT_NAME=accountname
			SET WAZ_STORAGE_ACCESS_KEY=accountkey

	* If you are running Node.js on **MacOS**, from a console:
		
			export WAZ_STORAGE_ACCOUNT_NAME=accountname
			export WAZ_STORAGE_ACCESS_KEY=accountkey
	
4. Create a new `views` folder with an `index.html` file inside with to display the list of containers retrieved from Azure:

		<!doctype html>
		<html lang="en">
			<head>
			  <title>WAZ Storage Sample</title>
			</head>
			<body>
				<h1>Containers</h1>
				<ul>
				<% for(var i=0;i<containers.length;i++) { %>
					<li><%= containers[i].name %></li>
				<% } %>
				</ul>
			</body>
		</html>

5. Intall the npm dependencies, from the command line:

		npm install

6. Run application locally:

		node web.js

7. Browse the application:

		http://localhost:3000
 
## Deploying the Applicattion to Heroku

To deploy the application you must have installed the [Heroku Toolbelt](http://devcenter.heroku.com/articles/quickstart). 

1. Create a [Procfile](http://devcenter.heroku.com/articles/procfile) in your project's root folder to declare the commands to run when the application is deployed to Heroku. In this case the `Procfile` will have only one row for running the website:

		web: node web.js

2. Create a `.gitignore` file in your project's root file with the following content:

		node_modules

3. Initialize a new git repository:

		git init
		git add .
		git commit -m "init"

4. Create a new application on Heroku specifying the cedar stack:
	
		heroku create your-application-name --stack cedar

5. Set the environment variables with your Azure account name and key:

		heroku config:add WAZ_STORAGE_ACCOUNT_NAME=accountname
		heroku config:add WAZ_STORAGE_ACCESS_KEY=accountkey

6. Deploy your application

		git push heroku master

6. That's it, now you can navigate your application at:

		http://your-application-name.herokuapp.com