Title: Browsing Blobs within a container using the Windows Azure Node SDK 
Author: Mariano Vazquez
Date: Thu Jan 30 2012 12:00:00 GMT-0300
Node: v0.6.6

The last couple of weeks we were working on a new, exciting project: a collaborative, real-time markdown editor that runs on a **NodeJS**  server, hosted on **Windows Azure** (you'll hear more about this soon). One of the features that this app will have is the ability to store the .markdown files in either your local disk or **Azure Blob Storage**. To achieve this, we investigated the best way to list the containers and blobs of a specific account, and navigate them like we were dealing with an hierarchical structure. We found out that this can be done, but is not as easy and it sounds (you have to use a combination of the **prefix** and **delimiter** options of the **listBlobs** operation, along with inspecting the **BlobPrefix** element returned in the Blobs REST API response). 

In the next lines, we are going to explain how you can implement this functionality in your application. We start from showing the blobs in a simple, flat-list to demonstrate how to organize them in a more complex structure, like if you were navigating your local file system directories.

To access blob storage, we used the [Windows Azure SDK for Node.js](https://github.com/WindowsAzure/azure-sdk-for-node) (you can install this module in your node application by doing `npm install azure`). Also, don't forget to install the [Windows Azure SDK for Node.js](https://www.windowsazure.com/en-us/develop/nodejs/) to emulate the Azure environment locally.

## Basic scenario

This is all the code you need to list the containers in your storage account, and show the blobs inside. Because all blobs are stored inside a container, you need to perform two separated calls: one to retrieve all containers in the account and other to retrieve the blobs inside a particular container. 

	var azure = require('azure');

	...

	function Home () {
		this.blobService = azure.createBlobService();
	};

	Home.prototype = {
	    showContainers: function (req, res) {
	        var self = this;
	        self.blobService.listContainers(function(err, result){
				// some code here to show the results
			});
	    },
		showBlobs: function(req, res){
			var self = this;
			var containerName = req.query['containerName'];
			if (!containerName)
				self.showContainers(req, res);
			else
				self.blobService.listBlobs(containerName, function(err, result){
					// some code here to show the results
				});
		},

		...
	};

Below is a sample result of what you may get. In this case, we listed only the blob names. Notice that the **listBlobs** operation is returning every blob within the container, using flat blob listing (more info about flat blob listing [here](http://msdn.microsoft.com/en-us/library/windowsazure/microsoft.windowsazure.storageclient.blobrequestoptions.useflatbloblisting.aspx)).

![](browsing-blobs-within-a-container-using-the-azure-node-sdk/simple-sample-result.png "Simple sample Result")

There's nothing wrong with the code above, and it might be sufficient for you and your business needs (actually, it will work great if all your blobs are children of the container). But what happens if your containers have a considerable amount of blobs, organized in a logic way, and you want to retrieve them in a lazy manner? If that's the case you're facing, keep reading.

## Using directories approach

You can filter the results of the **listBlob** operation by setting the **prefix** and **delimiter** parameters. The first one is used, as its name claims, to return only the blobs whose names begin with the value specified. The delimiter has two purposes: to skip from the result those blobs whose names contains the delimiter, and to include a **BlobPrefix** element in the [REST API](http://msdn.microsoft.com/en-us/library/windowsazure/dd135734.aspx) response body. 
This element will act as a placeholder for all blobs whose names begin with the same substring up to the appearance of the delimiter, and will be used to simulate a directory hierarchy (the folders will be listed there).


	var azure  = require('azure');

	...

	function Home () {
		this.blobService = azure.createBlobService();
	};

	function getFiles(collection){
		var items = [];
		for(var key in collection){
			var item = collection[key];
			var itemName = item.name.split('/')[item.name.split('/').length - 1];
			items.push({ 'text': itemName, 'classes': 'file'});
		}
		return items;
	}

	function getFolders(containerName, collection){
		var items = [];
		//if BlobPrefix contains one folder is a simple JSON. Otherwise is an array of JSONs
		if (collection && !collection.length){
			temp = collection;
			collection = [];
			collection.push(temp);
		}
		for(var key in collection){
			var item = collection[key];
			var itemName = item.Name.replace(/\/$/, '').split('/')[item.Name.replace(/\/$/, '').split('/').length - 1];
			items.push({ 'text': itemName, 'classes': 'folder' });
		}
		return items;
	}

	Home.prototype = {
    	
    	...

    	listBlobs: function(containerName, prefix, delimiter, callback){
			var self = this;
			self.blobService.listBlobs(containerName,{ 'prefix': prefix, 'delimiter': delimiter}, function(err, result, resultCont, response){
				if(!err){
					var files = getFiles(result);
					var folders = getFolders(containerName, response.body.Blobs.BlobPrefix);
					var childs = folders.concat(files);
					// return the childs
				}
			});
		},

    	...
	};

This is what we're doing in the lines above:

* First, we parse the result to access the blobs returned (by calling getFiles). 
* To generate the folders, we parse the **BlobPrefix** element (located inside the Response Body).
* Lastly, we join these two collections into one.

We created this [sample](https://github.com/nanovazquez/common/tree/master/azure-blob-explorer-tree-view) to demonstrate how you can use all of this in a real-world scenario. It shows you how to correctly parse the JSON returned by the **listBlobs** operation, and how to use this information to populate a control in the View, like a [jQuery Treeview Plugin](https://github.com/jzaefferer/jquery-treeview).

![](browsing-blobs-within-a-container-using-the-azure-node-sdk/treeview-sample-result.png "Showing the blobs in a TreeView")

Enjoy coding!