Title: Windows Azure Startup task to run npm install to avoid deploying node modules  
Author: Matias Woloski
Date: Tue Jan 03 2012 02:24:35 GMT-0300
Node: v0.6.6

Deploying to Windows Azure is a lengthy task (scottgu are you listening?) and you don't want to make it even slower by uploading a package with all the node modules inside. Last week while talking to [Johnny](http://johnny.io) we were wondering why Azure is not doing `npm install` and reading the package.json by default.
 
It turns out that there is a [heated debate](http://www.mikealrogers.com/posts/nodemodules-in-git.html) apparentely in the node community about whether or not pushing node_modules to the source control is a good idea. My take is: if you wire up your dependencies against fixed versions (instead of latest or greater than) you are safe. So if you think the same, this is a small tutorial of how to configure an Azure role to do the magic. I took many interesting snippets from the great [Steve Marx](http://smarx.com) blog.

## How to

The process consists basically of: 

1. creating a `cmd` that downloads `npm` (not installed in the Azure VM by default) and unzip it to the `bin` folder where `node.exe` is. 
2. add the `package.json` with your dependencies on the role root
3. configure the startup task in the `ServiceDefinition.csdef`

The batch that you will run from the startup task looks like this:

**install_modules.cmd**

	cd /d "%~dp0"

	if "%EMULATED%"=="true" exit /b 0

	echo npm LOG > npmlog.txt

	powershell -c "set-executionpolicy unrestricted"
	powershell .\download.ps1 "http://npmjs.org/dist/npm-1.1.0-beta-7.zip"

	7za x npm-1.1.0-beta-7.zip -y 1>> npmlog.txt 2>> npmlog_error.txt
	cd ..
	bin\npm install 1>> npmlog.txt 2>> npmlog_error.txt

	echo SUCCESS
	exit /b 0

	:error

	echo FAILED
	exit /b -1

There are a couple things worth mentioning

* We are downloading `npm` instead of including it in the package. Again, the lighter the better. 
* This will run in the context of the `bin` folder. I haven't found a way to execute npm on the parent folder, so I had to do `cd..`.
* We are redirecting the stdout and stderr to `npmlog.txt` and `npmlogerror.txt`. This is crucial in startup tasks if something goes wrong and you want to troubleshoot them by RD to the instance (`Enable-RemoteDesktop` PowerShell CmdLet saves you lots of time, so you should do it as soon as you did `New-AzureService`).
* If we are running in the Windows Azure emulator, we don't want this process to happen. We will have our modules already installed.

This is the `download.ps1`.

**download.ps1**

	$url = $args[0];

	function download([string]$url) {
	    $dest = $url.substring($url.lastindexof('/')+1)
	    if (!(test-path $dest)) {
	        (new-object system.net.webclient).downloadfile($url, $dest);
	    }
	}

	download $url

And you can use [7za](http://www.7-zip.org/download.html) to unzip or write your own unzipping function with PowerShell (thanks [Lito](http://twitter.com/litodam)!)

	function Extract-Zip
	{
		param([string]$zipfilename, [string] $destination)

		if(test-path($zipfilename))
		{             
            $shellApplication = new-object -com shell.application
            $zipPackage = $shellApplication.NameSpace($zipfilename)
            $destinationFolder = $shellApplication.NameSpace($destination)
            $destinationFolder.CopyHere($zipPackage.Items())
		}
	}

Finally, you will have to add the startup task to the `ServiceDefinition.csdef`

**ServiceDefinition.csdef**

	<Task commandLine="install_nodemodules.cmd" executionContext="elevated">
	    <Environment>
	      <Variable name="EMULATED">
	        <RoleInstanceValue xpath="/RoleEnvironment/Deployment/@emulated" />
	      </Variable>
	    </Environment>
	</Task>

And that's it! enjoy traveling light :)
