Title: Browsing Blobs within a container using the Windows Azure Node SDK 
Author: Mariano Vazquez
Date: Mon Jan 30 2012 18:00:00 GMT-0300
Node: v0.6.6

One of the main features in MarkdownR is the ability to store the .markdown files in **Azure Blob Storage**. To achieve this, we investigated the best way to list the containers and blobs of a specific account and navigate them *like you were working with the file system's directories*. We found out that using the **prefix** and **delimiter** options of **listBlobs**, along with inspecting the **BlobPrefix** element, we can access the blobs like we were dealing with an hierarchical structure. Additionally, we implemented a way to **filter** the blobs returned to only show, for instance, text type blobs.

In the next few lines, we are going to explain how you can achieve all of this, starting from showing the blobs in a simple flat-list to populate [jquery File Tree plugin](http://www.abeautifulsite.net/blog/2008/03/jquery-file-tree/) with the blob structure.

## Basic scenario
   
We developed this [sample]() so you can take a look of the basic functionality. To access blob storage, we used the [Windows Azure SDK for Node.js](https://github.com/WindowsAzure/azure-sdk-for-node) **blobService** object (you can install this module in your application by doing `npm install azure`). Below is the code you need to list the containers, and the blobs inside each one of them:

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

This is the simplest way to access the blobs & containers information. Because all blobs are stored inside a container, you need to perform two separated calls: one to retrieve all the containers in the account and other to retrieve the blobs inside a container.

This is the result you get if you run the sample: clicking one of the containers in the list you will get the names of the blobs inside it. Notice that **listBlobs** is returning ALL blobs inside the container, with no hierarchical structure whatsoever.

![](browsing-blobs-within-a-container-using-the-azure-node-sdk/simple-sample-result.png "Simple sample Result")

## Using directories approach



## Filtering the data
