Title: Using Windows Azure Access Control Service (ACS) from a node express app
Author: Matias Woloski
Date: Thu Jan 19 2012 9:00:00 GMT-0800
Node: v0.6.6

In this article we will explain how to use [Windows Azure Access Control Service][] (ACS) from a node.js applicaiton. You might be wondering, what else Widows Azure ACS will provide that everyauth already does. Windows Azure ACS will provide single-sign-on to applications written in different languates/platforms and will also allow you to integrate with "enterprise Security Token Service" like Active Directory Federaetion Services (ADFS), SiteMinder or PingFederate, a common requirement for Software as a Service applications targeted to enterprise customers.
 
To do the integration we decided to extend [everyauth][] which provided a good infrastructure to base our work on. 

If you want to **know how it works** and how it was implemented read [Implementing Windows Azure ACS with everyauth](/implementing-windows-azure-acs-with-everyauth) 

If you want to **know how to use** Windows Azure ACS in your node app keep reading. 

## How to configure your node application with everyauth and Windows Azure ACS

We are assuming that you already created the node.js Azure Service and added a node web role (`New-AzureService` and `Add-AzureNodeWebRole`) using the [SDK][] or you simply have a regular node app.

Follow these steps to add support for [everyauth][] and configure the parameters required by [Windows Azure Access Control Service][].

1. Add everyauth to your app `package.json` and execute `npm install` (we haven't send a pull request to everyauth yet, so for now you can point to `darrenzully` fork)

    	"everyauth": "https://github.com/darrenzully/everyauth/tarball/master"

2. Configure everyauth strategies. In this case we will configure only `azureacs`. You will need to create a [Windows Azure ACS namespace](http://msdn.microsoft.com/en-us/library/windowsazure/hh674478.aspx). The only caveat when creating the namespace is setting the "Return URL". You will probably [create one Relying Party](http://msdn.microsoft.com/en-us/library/windowsazure/gg429779.aspx) for each environment (dev, qa, prod) and each of them will have a different "Return URL". For instance, dev will be `http://localhost:port/auth/azureacs/callback` and prod could be `https://myapp.com/auth/azureacs/callback` (notice the `/auth/azureacs/callback`, that's where the module will listen the POST with the token from ACS)

		var everyauth = require('everyauth');
		everyauth.debug = true;  // true= if you want to see the output of the steps

		everyauth.azureacs
		  .identityProviderUrl('https://YOURNAMESPACE.accesscontrol.windows.net/v2/wsfederation/')
		  .entryPath('/auth/azureacs')
		  .callbackPath('/auth/azureacs/callback')
		  .signingKey('d0jul....YOUR_SIGNINGK=_KEY......OEvz24=')
		  .realm('YOUR_APPLICATION_REALM_IDENTIFIER')
		  .homeRealm('') // if you want to use a default idp (like google/liveid)
		  .tokenFormat('swt')  // only swt supported for now
		  .findOrCreateUser( function (session, acsUser) {
		     // you could enrich the "user" entity by storing/fetching the user from a db
		    return null;
		  });
		  .redirectPath('/');

3. Add the middleware to express or connect:

		var app = express.createServer(
		    express.bodyParser()
		  , express.static(__dirname + "/public")
		  , express.cookieParser()
		  , express.session({ secret: 'azureacssample'})
		  , express.bodyParser()
		  , express.methodOverride()
		  , everyauth.middleware()
		); 

4. Add the everyauth view helpers to express:

  		everyauth.helpExpress(app);

5. Render the login url, and user info/logout url on a view 
		
		- if (!everyauth.loggedIn)
			h2 You are NOT Authenticated
			p To see how this example works, please log in using the following link:
			#azureacs-login
				a(href='/auth/azureacs', style='border: 0px') Go to authentication server.
      	- else
        	h2 You are Authenticated
        	h3 Azure ACS User Data
        	p = JSON.stringify(everyauth.azureacs.user)
        h3
        	a(href='/logout') Logout
 
That's it, you can now run the app.

## Sample application

If you want to test the experience you can try <http://azureacs.cloudapp.net/> (we might take this down, so no warranties, if you want ro run it locally the code is @ <https://github.com/darrenzully/node-azureacs-sample>).

**IMPORTANT**: in production you should use HTTPS to avoid man in the middle and impersonation attacks

![](/using-windows-azure-access-control-service-acs-from-a-node-app/acslogin.png)

Enjoy node and federated identity!

[Windows Azure Access Control Service]: https://www.windowsazure.com/en-us/home/tour/access-control/
[SDK]: https://www.windowsazure.com/en-us/develop/nodejs/
[everyauth]: https://github.com/bnoguchi/everyauth