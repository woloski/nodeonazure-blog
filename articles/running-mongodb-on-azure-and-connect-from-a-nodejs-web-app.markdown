Title: Running Mongodb on Azure and connect from a node web app
Author: Mariano Vazquez
Date: Wed Jan 18 2012 18:00:00 GMT-0300
Node: v0.6.6

This post explains the basic steps you need to follow to make that your Node Web application starts storing the data in MongoDB Replica Sets, hosted on Windows Azure. For this, we'll use the new [Windows Azure tools for MongoDB and Node.js](), which contains some useful `ps` cmdlets that can (and will) save you a lot of time when developing.

We part from a node web application that uses the [mongodb-native](https://github.com/christkv/node-mongodb-native) driver to access a MongoDB Server, and in the next few lines, we'll add support to connect to Replica Sets stored in Azure. You can download the client from [here](https://github.com/nanovazquez/nodeonazure-blog/blob/master/articles/nodejs-web-app.zip) (run a `npm install` after you extract the code to download the necessary modules).

##The steps

First, you will need to create the MongoDB role that will take care of manage the Replica Sets. Each instance of this role will manage a Replica Set Node that stores data in a [Windows Azure Drive](https://www.windowsazure.com/en-us/develop/net/fundamentals/cloud-storage/#drives). Open the **Windows PowerShell for MongoDB Node.js** window from the **Start Menu**, navigate to the folder where you placed the **nodejs-web-app** and type the following command:

    Add-AzureMongoWorkerRole ReplicaSetRole 3

This will create a worker role named **ReplicaSetRole** with 3 role instances, but you can use the amount you want (is recommended to use more than 2, 1 instance is the equivalent to a stand-alone server)

Next, we will connect both Client and Server roles, using the next command:

    Join-AzureNodeRoleToMongoRole sample-web ReplicaSetRole

This is what the cmdlet does to the web role:

* Adds two [configuration settings](http://msdn.microsoft.com/en-us/library/windowsazure/ee758710.aspx#ConfigurationSettings) named RoleName & EndpointName. These settings will be used to connect to the Replica Sets. 
* Adds a startup task that launches the AzureEndpointsAgent.exe.
* Installs the **AzureEndpoints** module.

Now that we have both roles connected, let's add some code. We've already included the mongodb driver's code because what changes is how the client the client connects to the Replica Set Server, the rest is handled as usual. Open to the **moviesProvider.js** file, and add the following code inside the MoviesProvider constructor:

    // Create mongodb azure endpoint
    // TODO: Replace 'ReplicaSetRole' with your MongoDB role name (ReplicaSetRole is the default)
    var mongoEndpoints = new AzureEndpoint('ReplicaSetRole', 'MongodPort');

    // Watch the endpoint for topologyChange events
    mongoEndpoints.on('topologyChange', function() {
      if (self.db) {
        self.db.close();
        self.db = null;
      }
        
      var mongoDbServerConfig = mongoEndpoints.getMongoDBServerConfig();
      self.db = new mongoDb('test', mongoDbServerConfig, {native_parser:false});
      
      self.db.open(function(err, client) {
          if (!err){
              self.fillCollectionIfEmpty(client);
          }
          else
              throw err;
      });
    });

    mongoEndpoints.on('error', function(error) {
      throw error;
    });

The mongoEndpoints will listen the running MongoDB Replica Set nodes and will be updated automatically if one of the nodes come on or off line.


And that's it! You can now test the application if you want (by the way, is a movie repository if you don't figure it out yet)

![](/running-mongodb-on-azure-and-connect-from-a-nodejs-web-app/movies-app.png)

NOTE: The MongoDB nodes take some time to initialize. If you test the application in the local emulator, using the `-launch` option it's probably that you get a **no primary server found** error. If this happens, wait a few seconds and try again.