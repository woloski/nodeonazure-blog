Title: Develop on Mac, host on GitHub, and deploy to Windows Azure
Author: Tomasz Janczuk
Date: Thu May 24 2012 10:30:00 GMT-0700
Node: v0.7.6

If you are like most node.js developers, you develop your code on a Mac and host it on GitHub. With [git-azure](http://github.com/tjanczuk/git-azure) you can now deploy that code to Windows Azure without ever leaving your development environment. 

## What is git-azure?

Git-azure is a tool and runtime environment that allows deploying multiple node.js applications in seconds into Windows Azure Worker Role from MacOS using Git. Git-azure consists of three components: a git-azure runtime, a command line tool integrated into ```git``` toolchain, and your own Git repository (likely on GitHub). 

The git-azure runtime is a pre-packged Windows Azure service that runs HTTP and WebSocket reverse proxy on an instance of Windows Azure Worker Role. The proxy is associated with your Git repository that contains one or more node.js applications. Incoming HTTP and WebSocket requests are routed to individual applications following a set of convention based or explicit routing rules. 

The git-azure command line tool is an extension of the ```git``` toolchain and accessible with the ```git azure``` command. It allows you to perform a one-time deployment of git-azure runtime associated with your Git repository to Windows Azure, after which adding, modifying, and configurting applications is performend with regular ```git push``` commands and take seconds. The ```git azure``` tool also helps with scaffolding appliations, configuring routing and SSL, and access to Windows Azure Blob Storage. 

## Getting started with git-azure

For detailed and up to date walkthrough of using git-azure see [the project site](http://github.com/tjanczuk/git-azure). High level, this is how you get started with git-azure:

First, install the git-azure tool:

	sudo npm install git-azure -g

Then download your *.publishSettings file for your Windows Azure account from <https://windows.azure.com/download/publishprofile.aspx>, go to the root of your Git repository, and call:

	git config azure.publishSettings <path_to_your_publishSettings_file>
	git azure init --serviceName <your_git_azure_service_name>

The git-azure tool will now provision your Windows Azure hosted service with git-azure runtime associated with your Git repository. This one-time process takes several minutes, after which you can add, remove, and modify applications in seconds, as long as you configure your Git repository with a post-receive hook following the instructions ```git azure init``` provides on successful completion. 

Here is a screenshot of the terminal running the initialization process triggered by ```git azure init```

<img src="/develop-on-mac-host-on-github-and-deploy-to-windows-azure/gitazureinit.png" width="100%" />

## Host multiple apps in the same Windows Azure VM instance

To add two applications, call:

	git azure app --setup hello1
	git azure app --setup hello2
	git add .
	git commit -m "new applications"
	git push

Your apps are available within seconds at 

* ```http://<your_git_azure_service_name>.cloudapp.net/hello1``` 
* ```http://<your_git_azure_service_name>.cloudapp.net/hello2```

## Advanced usage (WebSockets, SSL) and next steps

The git-azure tool and runtime come with support for URL path as well as host name routing, WebSockets, SSL for HTTP and WebSockets (including custom certificates for each host name using Server Name Identification), and full RDP access to the Windows Azure VM for diagnostics and monitoring. Going forward, I plan to add support for accessing live logs in real time from the client, SSH access to Windows Azure VM, and support for multi-instance Azure deployments. 

I do take contributions. If you want to contribute, get in touch and we will go from there. Otherwise, feel free to drop opinions and suggestions by [filing an issue](https://github.com/tjanczuk/git-azure/issues). 