Title: Hosting multiple node applications in the same Windows Azure role instance
Author: Matias Woloski
Date: Tue Jan 10 2012 14:10:35 GMT-0300
Node: v0.6.6

One of the good things about Windows Azure is that a web role is a full VM (extra-small, small, medium, large or xl) just for you. You can even do remote desktop to it. So what's interesting about that? That you can host multiple websites in the same IIS, hence save some $$ and make good use of the virtual machine resources. 

Declaring multiple web sites in your `ServiceDefinition.csdef` file is supported since 1.3 version. [Wade Wegner](http://www.wadewegner.com/) has a [nice post](http://www.wadewegner.com/2011/02/running-multiple-websites-in-a-windows-azure-web-role/) that explains how to make use of that feature within the context of ASP.NET web roles. However, the current version of the [Windows Azure SDK for Node.js] does not support running multiple node apps in the same instance. So in this article, we will explain how to deploy multiple node.js applications to the same Windows Azure role/VM and get the most out of your money.

## How to deploy multiple node apps in the same Azure instance

Assuming you already created the Azure Service and added a node web role (`New-AzureService` and `Add-AzureNodeWebRole`), what you have to do is: 

1. Copy the folder created by `Add-AzureNodeWebRole` except the bin folder, into a new folder, let's say `mysecondnodeapp`. You should have the server.js + Web.config + Web.cloud.config only in the `mysecondnodeapp` folder. 
2. Change and code this new app
3. When you are ready to deploy, change the `ServiceDefinition.csdef` file to include the new app in the manifest (notice the new `<Site>` and `<InputEndpoint>` elements).

**ServiceDefinition.csdef**

	<WebRole name="nodeapps" vmsize="ExtraSmall">
	    <Imports>
	    	...
	    </Imports>
	    <Startup>
	      <Task commandLine="setup_web.cmd" executionContext="elevated">
	        ...
	      </Task>
	    </Startup>
	    <Endpoints>
	      <InputEndpoint name="Endpoint1" protocol="http" port="80" />
	      <InputEndpoint name="port8090" protocol="http" port="8090" />
	    </Endpoints>
	    <Sites>
	      <Site name="Web" physicalDirectory="myfirstnodeapp">
	        <Bindings>
	          <Binding name="Endpoint1" endpointName="Endpoint1" />
	        </Bindings>
	      </Site>
	      <Site name="Web2" physicalDirectory="mysecondnodeapp">
	        <Bindings>
	          <Binding name="port8090" endpointName="port8090" />
	        </Bindings>
	      </Site>
	    </Sites>
	</WebRole>

Two things to highlight here:

* We added a new `<Site>` element and a new `<InputEndpoint>` (8090). We are associating that new site with the endpoint just created. We could have used a host header attribute instead of a port `<Site name="Web2" physticalDirectory="mysecondnodeapp" hostHeader="superapp.mydomain.com">`. This is assuming you manage your DNS or you can test it changing the HOSTS file in your machine.
* We are setting the `physicalDirectory` to point to each node application folder.

Finally the most important step, deploying. You won't be able to use the `Publish-AzureService` Cmdlet. Instead you will have to use `cspack.exe` and deploy separately (either through the portal or using the [Windows Azure PowerShell Cmdlets](http://wappowershell.codeplex.com/). 

Open a command prompt at the root of your Azure Service and execute the following:

	"C:\Program Files\Windows Azure SDK\v1.6\bin\cspack.exe" ServiceDefinition.csdef 
	/role:name-of-the-role;folder-of-the-first-node-app /out:name-of-the-package.cspkg

Replace:

* _name-of-the-role_ with the attribute `name` of the `<WebRole>` element in the ServiceDefinition.csdef file
* _folder-of-the-first-node-app_ with the folder name where the first node application was created (the one created by `Add-AzureNodeWebRole`)
* _name-of-the-package_ with a friendly name you want to give to the package generated.

Here is some evidence that this is working:

![Multiple apps running in the same instance](hosting-multiple-node-apps-in-the-same-azure-instance/multipleapps.png "Multiple apps running in the same instance")

Notice the first IE is showing the app running on port 80 and the second is running on port 8090. The app simply prints a message and the port iisnode is assigning (iisnode uses named pipes). 

## What is missing from this solution?

This is a half-baked solution since:

* It does not work in the local Windows Azure emulator

The `Start-AzureEmulator` Cmdlet is pointing the second website in IIS to the original website. As a temporal workaround, if you want to run it locally you could run each app  through the usual `node.exe server.js`. 

* You can't run a startup script for the second app (for instance to [download the npm modules](/startup-task-to-run-npm-in-azure)).

Implementing that should be easy by creating a startup task that executes a `setup.cmd` that is located in the bin folder of the second website. Not sure how to obtain the path of that second website though. Something to research on. 

## Taking it to the next level

It would be nice to see built-in support in the [Windows Azure SDK for Node.js][] for this scenario. I can see two changes: 

1. One is changing `Publish-AzureService` so that it behaves correctly when you have multiple node apps. 
2. The other one is implementing a new Cmdlet `Add-AzureNodeWebSite` that executes in the context of a node web role and scaffold a new node app and change the ServiceDefinition.csdef adding the physicalDirectory and the endpoint (with a port or host header).

Happy node on Windows! 
 
[Windows Azure SDK for Node.js]: http://www.azurehub.com/en-us/develop/nodejs/
