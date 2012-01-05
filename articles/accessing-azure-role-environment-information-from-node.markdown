Title: Accessing Azure Role Environment information from NodeJS
Author: Mariano Vazquez 
Date: Tue Jan 05 2012 10:32:35 GMT-0300
Node: v0.6.6

One of the things you may want to do while working on Azure is to obtain information about your role environment, like the current role instance name, the DeploymentID or even know if the role instance is running or not. This can be tricky if you use NodeJS, because you (apparently) cannot use the [RoleEnvironment](http://msdn.microsoft.com/es-es/library/ee773173.aspx) class to obtain that information. In this article I'm going to explain how you can set up information of your running Azure role to be easily accessed from a NodeJS server.

I've created this [sample](http://<SAMPLE LOCATION) that does the trick so you can test it by yourself. Basically, it contains a startup task that dumps the Azure role environment info in Environment variables and a server.js file to outputs those variables. Anyway, in the next few lines you can read a deep explanation about how to do it.

## What you need to do

In small words, you need to: 

1. Create a startup task to launch a `cmd` script that access the Azure Role environment info.
2. Set the info in Environment variables so it can be accessed from NodeJS.
3. Obtain the values in the server.js file via the *process.env* objet.

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
	CALL %powerShellDir%\powershell.exe -Command Set-ExecutionPolicy restricted
	ECHO Done!

	ECHO Restarting IIS..
	CALL iisreset
	ECHO Done!

	ECHO Starting the W3SVC service..
	CALL NET START W3SVC
	ECHO Done!

Some things to mention about this code:

* To execute an unsigned `ps` script in Azure you have to set the *Execution Policy* to *Unrestricted*. I'm using the *Set-ExecutionPolicy* command for this, but take into account that this won't change unless you do it manually. In PS 2.0 you can use the *-ExecutionPolicy* command to set to unrestricted only for the current scope. But since the default template uses *osFamily="1"* that came with PS 1.0, I decided to leave this way ([smarx](http://blog.smarx.com/posts/windows-azure-startup-tasks-tips-tricks-and-gotchas) wrote something about this)
* After the Environment variables are set, you need to restart IIS so the changes take effect in the service.
* Lasty, if you deploy this sample in Azure, you will need to restart the *w3svc* service manually

Now let's dig into the ´PS´ script.

**set_azure_role_information.ps1**

	[Reflection.Assembly]::LoadWithPartialName("Microsoft.WindowsAzure.ServiceRuntime")
	[Environment]::SetEnvironmentVariable("RoleName", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::CurrentRoleInstance.Role.Name, "Machine") 
	[Environment]::SetEnvironmentVariable("RoleInstanceID", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::CurrentRoleInstance.Id, "Machine")
	[Environment]::SetEnvironmentVariable("RoleDeploymentID", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::DeploymentId, "Machine")
	[Environment]::SetEnvironmentVariable("IsAvailable", [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::IsAvailable, "Machine") 
	[Environment]::SetEnvironmentVariable("CustomVariable", "Some value", "Machine")

What I'm doing is setting some RoleEnvironment properties in Environment variables. Simple enough. Notice that you can also set a custom variable there if you want.

This is the Startup task that puts everything into motion.

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

This is the result you get if you deploy the sample:

![Alt text](/accessing-azure-role-environment-information-from-node/deployedSampleTask.png "deployment results")