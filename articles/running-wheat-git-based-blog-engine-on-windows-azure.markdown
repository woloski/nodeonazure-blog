Title: Running wheat git-based blog engine on Windows Azure 
Author: Matias Woloski
Date: Tue Jan 06 2012 12:10:35 GMT-0300
Node: v0.6.6

In this article I will go through the details of setting up a blog on top of [wheat][] and run it on Windows Azure.

1. How [wheat]() works
2. Bootstrapping from an existing blog
3. Run it on the Windows Azure emulator
4. Deploy it to Azure
5. Setting up the hook

### How [wheat][] works?

[wheat][] is a blog engine based on git and was written by [creationix][]. The articles exists on a [github repository](http://github.com/woloski/nodeonazure-blog) and there is a bare repository running on the [Windows Azure](http://windows.azure.com) VM that gets updated everytime we push to github. So the actual files are not in Windows Azure. [Wheat][] will execute git commands against the bare repository to take data out from that bare repo (`git log`, `git show`, etc.). 

I could have setup a git server on Windows Azure and push there but instead I decided to push to github and setup a post-receive git hook that will POST to  nodeblog.cloudapp.net/hook and update the bare repo. I had to write that little piece of code that will execute `git fetch`. 

	function handleGitHook(req, res, next) {
		if (req.method == 'POST' && req.url == '/hook') {
	  		gitExec(['--git-dir=' + gitRepoPath, 'fetch'], 'utf8', function (err, text) {
	    		if (err) {
	    			console.log(err);
	    			res.writeHead(500);
	   				res.end(err);
	    		} else {
	    			console.log(text);
	    			res.writeHead(200);
	   				res.end('OK');	
	    		}
	  		});
	   }
	   else {
			next();   	
	   }	
	}

If you want to see how the article is retrieved browse to `data.js` (in [wheat\data.js in github](https://github.com/creationix/wheat/blob/master/lib/wheat/data.js)). It uses another node package called [node-git][].

Below a snippet of code showing an article being retrieved from git. Notice the `Git.readFile` that will use [node-git][]. Once it reads the article markdown inside the `articles` folder it will read the author information from the `authors` folder. It uses [Step](https://github.com/creationix/step), an async control flow library also written by [creationix][]

	article: Git.safe(function article(version, name, callback) {
	    var props;
	    Step(
	      function getArticleMarkdown() {
	        Git.readFile(version, "articles/" + name + ".markdown", this);
	      },
	      function (err, markdown) {
	        if (err) { callback(err); return; }
	        props = preProcessMarkdown(markdown);
	        if (props.author) {
	          Data.author(version, props.author, this);
	        } else {
	          return {};
	        }
	      },
	      function finish(err, author) {
	        if (err) { callback(err); return; }
	        props.name = name;
	        if (version !== 'fs') {
	          props.version = version;
	        }
	        props.author = author;

	        if(props.categories != undefined){
	          props.categories = props.categories.split(',').map(function(element){ 
	            return QueryString.escape(element.trim());
	          });
	        }
	        return props;
	      },
	      callback
	    );
	  }),

We can also write snippets of code in JavaScript and run them in a sandboxed node.js VM. The snippet below is actually running on the server!

<running-wheat-git-based-blog-engine-on-windows-azure/test.js*>

I had to do some changes on the code since it didn't work properly on Windows. One of them is changing the regex that matches the syntax in markdown include \r\n (instead of just \n). Another one was due to a change in the latest node version. To run a script you have to `require('vm')` instead of `process.binding('evals').Script`. This package provides a `runInNewContext` method to eval a piece of js in a sandboxed environment.

I am submitting the patches to [wheat][] and so far [creationix][] has pulled them pretty fast. However, the package has not been updated in npm yet so I am including a patched version of the `data.js` file in my repo.

### Bootstrapping from an existing blog

So [wheat][] is just the engine. If you want a bootstrap your own blog you should start from an existing blog. You could clone [howtonode.org][] repo or [nodeblog.cloudapp.net][] that already have some skins to render the articles. If you will run on Windows Azure you should start from cloning [nodeblog.cloudapp.net][] since there are a couple of things fixed and also it's already Azure friendly.

### Run it on Windows on the Windows Azure emulator

Before deploying, you can run it on the Azure emulator. To do that you will have to install the [Windows Azure SDK for Node.js](http://www.azurehub.com/en-us/develop/nodejs/). The SDK comes with a PowerShell module that provides a set of CmdLets to easily create Azure packages.

These are the steps:

1. Open the `Windows Azure PowerShell for Node.js` console
2. Go to whatever folder you want to have this running and type `New-AzureService 'yourblogname'`
3. Then we will add the node web role that will run node on top of IIS using iisnode: `Add-AzureNodeWebRole 'noderole'`
4. Download the [nodeblog.cloudapp.net][] repo and simply replace the content of the `noderole` folder just created with the content of the repo.
5. `Start-AzureEmulator -Launch`
6. `start [http://localhost:81](http://localhost:81)` 

You should have git installed and make sure git.exe is in the PATH.

### Deploy it to Azure

Before deploying to Windows Azure we will have to do a couple of things. Since Azure will give us a bare VM, before the node.js server runs we will have to:

1. Download portable git on the server
2. Setup the git bare repo with our blog content

To do that we need to create a startup task

**setup_git.cmd**

	cd /d "%~dp0"

	if "%EMULATED%"=="true" exit /b 0

	echo LOG > setup_git_log.txt

	REM remove trailing slash if any
	IF %GITPATH:~-1%==\ SET GITPATH=%GITPATH:~0,-1%
	IF %GITREPOBLOGPATH:~-1%==\ SET GITREPOBLOGPATH=%GITREPOBLOGPATH:~0,-1%

	echo GITPATH= %GITPATH% 1>> setup_git_log.txt
	echo GITREPOBLOGPATH= %GITREPOBLOGPATH% 1>> setup_git_log.txt
	echo GITREPOURL= %GITREPOURL% 1>> setup_git_log.txt

	if "%EMULATED%"=="true" exit /b 0

	powershell -c "set-executionpolicy unrestricted" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
	powershell .\download.ps1 "http://msysgit.googlecode.com/files/PortableGit-1.7.8-preview20111206.7z" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
	powershell .\appendPath.ps1 "%GITPATH%\bin" 1>> setup_git_log.txt 2>> setup_git_log_error.txt

	7za x PortableGit-1.7.8-preview20111206.7z -y -o"%GITPATH%" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
	echo y| cacls "%GITPATH%" /grant everyone:f /t 1>> setup_git_log.txt 2>> setup_git_log_error.txt
	"%GITPATH%\bin\git" clone --mirror %GITREPOURL% "%GITREPOBLOGPATH%" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
	echo y| cacls "%GITREPOBLOGPATH%" /grant everyone:f /t 1>> setup_git_log.txt 2>> setup_git_log_error.txt

	REM add GITREPOBLOGPATH as a system env variable to be used by node
	powershell "[Environment]::SetEnvironmentVariable('GITREPOBLOGPATH', '%GITREPOBLOGPATH%', 'Machine')" 1>> setup_git_log.txt 2>> setup_git_log_error.txt 

	IISRESET  1>> setup_git_log.txt 2>> setup_git_log_error.txt 
	NET START W3SVC 1>> setup_git_log.txt 2>> setup_git_log_error.txt 

	echo SUCCESS
	exit /b 0

	:error

	echo FAILED
	exit /b -1

This is what the script is doing

* Download portable git from `http://msysgit.googlecode.com/files/PortableGit-1.7.8-preview20111206.7z`
* Append the GITPATH environment variable that contains the path to the LocalResource (this is a read/write folder that we can setup in Azure called LocalResource)
* Unzip with 7za to the GITPATH folder
* Give full permissions to Everyone on the git folder
* Execute `git clone --mirror` to setup the git bare repository on the %GITREPOBLOGPATH% folder
* Give full permissions to Everyone on the bare repository
* Add the GITREPOBLOGPATH environment variable as a 'Machine' scope variable. We do that because we want to read that from the `server.js`
* Restart IIS and restart the W3SVC service. This is an important step otherwise the Environment variables won't be pick up.

Some of this environment variables are defined in ServiceDefinition.csdef and live in the context of the startup task only. Here is part of this file where you can see those definitions.

**Part of ServiceDefinition.csdef**
	<LocalResources>
      <LocalStorage name="GitRepoBlogPath" sizeInMB="1000" />
      <LocalStorage name="Git" sizeInMB="1000" />
    </LocalResources>

	<Startup>
      <Task commandLine="setup_web.cmd" executionContext="elevated">
        <Environment>
          <Variable name="EMULATED">
            <RoleInstanceValue xpath="/RoleEnvironment/Deployment/@emulated" />
          </Variable>
        </Environment>
      </Task>
      <Task commandLine="setup_git.cmd" executionContext="elevated">
        <Environment>
          <Variable name="EMULATED">
            <RoleInstanceValue xpath="/RoleEnvironment/Deployment/@emulated" />
          </Variable>
          <Variable name="GITPATH">
            <RoleInstanceValue xpath="/RoleEnvironment/CurrentInstance/LocalResources/LocalResource[@name='Git']/@path" />
          </Variable>
          <Variable name="GITREPOBLOGPATH">
            <RoleInstanceValue xpath="/RoleEnvironment/CurrentInstance/LocalResources/LocalResource[@name='GitRepoBlogPath']/@path" />
          </Variable>
          <Variable name="GITREPOURL" value="git://github.com/woloski/nodeonazure-blog.git" />
        </Environment>
      </Task>
      <Task commandLine="install_nodemodules.cmd" executionContext="elevated">
        <Environment>
          <Variable name="EMULATED">
            <RoleInstanceValue xpath="/RoleEnvironment/Deployment/@emulated" />
          </Variable>
        </Environment>
      </Task>
      <Task commandLine="patch_wheatmodule.cmd" executionContext="elevated">
        <Environment>
          <Variable name="EMULATED">
            <RoleInstanceValue xpath="/RoleEnvironment/Deployment/@emulated" />
          </Variable>
        </Environment>
      </Task>
    </Startup>
	
The whole `ServiceDefinition.csdef` file is [here](https://github.com/woloski/nodeonazure-blog/tree/master/articles/running-wheat-git-based-blog-engine-on-windows-azure)

The scripts used in the startup task are [here](https://github.com/woloski/nodeonazure-blog/tree/master/bin)

If everything runs fine now we can publish to Azure

1. If you haven't deployed to Azure before you can follow this [tutorial](http://www.azurehub.com/en-us/develop/nodejs/tutorials/web-app-with-express/) written by [Glenn Block](http://twitter.com/gblock) that will walk you through the process.

2. Basically you have to setup an free trial 3 months account, use the `Import-AzurePublishSettings`, and run `Publish-AzureService 'nameofyoursite'`

![node blog running on Azure](running-wheat-git-based-blog-engine-on-windows-azure/azure.png "node blog running on Azure")

### Setting up the hook

Finally you have to do the hook setup on github. That was simple, it's in the Admin area.

![post-receive hook on github](running-wheat-git-based-blog-engine-on-windows-azure/hook.png "post-receive hook on github")

## Conclusion

This is it. [Wheat][] and all these git-based blogs are powerful. What I liked about [wheat][] compared to [jekyll](http://github.com/mojombo/jekyll) is that it will run on Windows or Mac without too much effort, since node has native support for both. However, jekyll has a broader ecosystem. There are more plugins and more functionallity baked in.

The publishing process is perfect for devs. You can push to your repo and the blog will be automagically updated. [Tim](https://github.com/creationix) did some perf tests and he got 2000 requests/sec (not sure the hardware he used) but that should be enough for any blog. 
And you get to use markdown to edit text files, which together with [sublime text 2](http://www.sublimetext.com/2) is the perfect couple. Finally, if you use github you get the pull requests mechanism for contributions and the editing process. What else can we ask?  :)

Happy node on Windows! 
 
[wheat]: http://github.com/creationix/wheat
[howtonode.org]: http://github.com/creationix/howtonode.org
[node-git]: https://github.com/creationix/node-git
[creationix]: https://github.com/creationix
[nodeblog.cloudapp.net]: http://github.com/woloski/nodeonazure-blog