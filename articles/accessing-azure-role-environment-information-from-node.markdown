Title: Accessing Azure Role Environment information from NodeJS
Author: Mariano Vazquez
Date: Fri Jan 06 2012 15:42:35 GMT-0300
Node: v0.6.6

One of the things you may want to do while working on Azure is to obtain information about your role environment. The current role instance name, the DeploymentID or even know if the role instance is running or not. This can be tricky if you use NodeJS, because the [RoleEnvironment](http://msdn.microsoft.com/es-es/library/ee773173.aspx) class is managed .net code. In this article we'll going to explain how you can set up information of your running Azure role to be easily accessed from a NodeJS server. The trick is using environment variables and use startup tasks running PowerShell as the bridge.

I've created this [sample](https://github.com/nanovazquez/nodeonazure-blog/tree/master/articles/accessing-azure-role-environment-information-from-node/startup-task-sample) that shows everything so you can test this yourself. Basically, it contains a startup task that dumps the Azure role environment info into Environment variables and a server.js file to outputs those variables. Anyway, in the next few lines you can read a deeper explanation about how to do it.

## What you need to do

This is pretty much what you have to do: 

1. Create a startup task to launch a `cmd` script that access the Azure Role environment info.
2. Set the info in Environment variables so it can be accessed from NodeJS.
3. Obtain the values in the *server.js* file via the *process.env* objet.

So let's get into it. The `cmd` script looks like this:

**setup_environment_variables.cmd**

	@ECHO off
	%~d0
	CD "%~dp0"

	IF EXIST %WINDIR%\SysWow64 (
	set powerShellDir=%WINDIR%\SysWow64\windowspowershell\v1.0
	) ELSE (
	set powerShellDir=%WINDIR%\system32\windowspowershell\v1.0
	)

	ECHO Setting the Environment variables..
	CALL %powerShellDir%\powershell.exe -Command Set-ExecutionPolicy unrestricted
	CALL %powerShellDir%\powershell.exe -Command "& .\set_azure_role_information.ps1"
	ECHO Done!

	ECHO Restarting IIS..
	CALL iisreset
	ECHO Done!

	ECHO Starting the W3SVC service..
	CALL NET START W3SVC
	ECHO Done!

Some things to mention about this code:

* To execute an unsigned `ps` script in Azure you have to set the **Execution Policy** to **Unrestricted**. I'm using the **Set-ExecutionPolicy** command for this, but take into account that this value won't change unless you do it manually. [Lito](http://twitter.com/litodam) pointed me out that in PowerShell 2.0 you can use the **-ExecutionPolicy** command to set to **unrestricted** only for the current scope. But since the default WebRole template uses **osFamily="1"** which is Windows Server 2008 SP2 that coms with PowerShell 1.0, we will leave it this way ([smarx](http://blog.smarx.com/posts/windows-azure-startup-tasks-tips-tricks-and-gotchas) wrote something about this as well)
* IMPORTANT: After the Environment variables are set, you need to restart IIS and restart the W3SVC so the changes take effect in the service. The W3SVC in Azure is set to Manual mode that's why it does not autostart aftet iisreset.

Now let's dig into the `ps` script.

**set_azure_role_information.ps1**

	[Reflection.Assembly]::LoadWithPartialName("Microsoft.WindowsAzure.ServiceRuntime")
	[Environment]::SetEnvironmentVariable("RoleName", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::CurrentRoleInstance.Role.Name, "Machine") 
	[Environment]::SetEnvironmentVariable("RoleInstanceID", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::CurrentRoleInstance.Id, "Machine")
	[Environment]::SetEnvironmentVariable("RoleDeploymentID", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::DeploymentId, "Machine")
	[Environment]::SetEnvironmentVariable("IsAvailable", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::IsAvailable, "Machine") 
	[Environment]::SetEnvironmentVariable("CustomVariable", "Some value", "Machine")

What we're doing is setting some Environment variables with `RoleEnvironment` property values. Notice that you can also set a custom variable, if you want.

This is the Startup task that puts everything together.

**ServiceDefinition.csdef**

	<Task commandLine="setup_environment_variables.cmd" executionContext="elevated" taskType="simple" />

And finally, below is the server.js file that writes the results in the response.

**server.js**

	var http = require('http');
	var port = process.env.port || 1337;

	http.createServer(function (req, res) {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    
	res.write("Role Name: " + process.env.RoleName + "\n");
	res.write("Role InstanceID: " + process.env.RoleInstanceID + "\n");
	res.write("Role DeploymentID: " + process.env.RoleDeploymentID + "\n");
	res.write("Is running?: " + process.env.IsAvailable + "\n");
	res.write("Custom variable: " + process.env.CustomVariable + "\n");
	
	res.end();
	}).listen(port);

This is the result you get if you run the sample in the emulator:

![Alt text](accessing-azure-role-environment-information-from-node/test-sample-task.png "Showing the Azure Role Information")