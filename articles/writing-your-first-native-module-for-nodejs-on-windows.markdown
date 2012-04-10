Title: Writing your first native module for node.js on Windows
Author: Jose Romaniello
Date: Tue Apr 10 2012 11:42:35 GMT-0300
Node: v0.6.6


In this article I will guide you on how to write a native module for node.js in Windows using Visual Studio.

# About the example

In this example we are going to build a module to log events to the Windows Event Log. The project is already published in [[1] github](https://github.com/jfromaniello/windowseventlogjs) and you can install it with npm.

# I like it, but why native?

There are several reasons why you would build a native extension for node.js, but for me the most important reason is when you want to use an API that doesn't have an open or well documented protocol and the vendor only provides a native library. Of course it can also happen that the protocol is well documented and open but it was easier to interface the native implementation than writing a javascript client from scratch (E.g. the mongodb package).
In this case we are talking about the Windows Event Log which is a component of the operative system.

# I don't speak c++ 

The code that I am going to show well... it might have several problems. The thing is that my c++ skills are close to my English skills. I can read it and I can write it but as Russ Olsen say (for ruby) I have not absorb the "c++ way" of thinking and problem solving. So, *please* if you think that something could be improved just tell me.

# C++/CLI

C++/CLI is a Microsoft's evolution of the c++ language invented by Bjarne Stroustrup. The name is a tuple "C++" and "CLI", CLI means "Command Language Infrastructure" which is the specification for the .Net framework. So, you can think of c++/cli as:

 * The way you write c++ for the .Net framework
 * Interoperability between the c++ model and the .net framework 
In this examples I will use the .Net class [[2]System.Diagnostic.EventLog](http://msdn.microsoft.com/en-us/library/system.diagnostics.eventlog.aspx). 

# Configuring the environment 

The first thing you will need to do is to download the  [[3]Node.js source code](http://nodejs.org/#download) and uncompress it somewhere in your disk.
Then you will have to build the source code by running the vcbuild.bat file.
Note: the build process needs python 2.x installed and it should be accesible from the path.

# Creating the project in Visual Studio

1-Create a new "CLR Empty Project":

![2012-04-10_0953.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_0953.png)

2-Do these changes to the project settings:

![2012-04-10_0956.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_0956.png)

3-Add these directories to the Include Directories (remember to change C:\node-v0.6.14\ with the path where you have the node.js sources)

![2012-04-10_1003.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1003.png)

4-Change the Libraries Directories as follows:

![2012-04-10_1008.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1008.png)

5-Add a new "C++ File (.cpp)" called "EventLog", so your solution has to look as:

![2012-04-10_1043.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1043.png)

Note: that the cpp file that we add has to be /CLR. 

# Show me the code

*Nitpicker corner: Don't get overwhelmed!*
I wrote some comments in the source to explain the different pieces:

**EventLog.cpp**
	#pragma comment(lib, "node")

	#using <mscorlib.dll>
	#using <system.dll>

	#include <node.h>
	#include <v8.h>
	#include <string>
	#include <gcroot.h>
	#include <string>
	#include <iostream>
	#include <uv.h>

	using namespace node;
	using namespace v8;

	class EventLog : ObjectWrap
	{
	private:
		//the field that will hold an instance of System.Diagnostics.EventLog
		gcroot<System::Diagnostics::EventLog^> _eventLog;

	public:
		
		static Persistent<FunctionTemplate> s_ct;
		
		//module initialization
		static void NODE_EXTERN Init(Handle<Object> target)
		{
			HandleScope scope;

			// set the constructor function
			Local<FunctionTemplate> t = FunctionTemplate::New(New);

			// set the node.js/v8 class name
			s_ct = Persistent<FunctionTemplate>::New(t);
			s_ct->InstanceTemplate()->SetInternalFieldCount(1);
			s_ct->SetClassName(String::NewSymbol("EventLog"));

			// registers a class member functions 
			NODE_SET_PROTOTYPE_METHOD(s_ct, "log", Log);
			
			target->Set(String::NewSymbol("EventLog"),
				s_ct->GetFunction());
		}
		
		//Constructor
		//Source: the name of the event log we will use
		//LogName: the logName could be Application, System, or a new one.
		EventLog(System::String^ source, System::String^ logName) 
		{
			if(!System::Diagnostics::EventLog::SourceExists(source)){
				System::Diagnostics::EventLog::CreateEventSource(source, logName);
			}
			
			_eventLog = gcnew System::Diagnostics::EventLog();
			_eventLog->Source = source;
		}

		//finalizer, kill the _eventLog.
		//This will call the IDisposable
		~EventLog()
		{
			delete _eventLog;
		}

		//Transform a v8 argument to a .Net String
		static inline gcroot<System::String^> ParseArgument(Arguments const&args, int argumentIndex)
		{
			Local<String> message = Local<String>::Cast(args[argumentIndex]);
			gcroot<System::String^> m = gcnew System::String(((std::string)*v8::String::AsciiValue(message)).c_str());
			return m;
		}

		//This is the method that call node will call when we do *new EventLog(...)*
		//Note that it looks as a Javascript func since it returns "this"
		static Handle<Value> New(const Arguments& args)
		{
			HandleScope scope;

			if (!args[0]->IsString()) {
				return ThrowException(Exception::TypeError(
					String::New("First argument must be the name of the event log source")));
			}
			if (!args[1]->IsString()) {
				return ThrowException(Exception::TypeError(
					String::New("Second argument must be the name of the event log: (Application, System)")));
			}

			System::String^ s = ParseArgument(args, 0);
			System::String^ ln = ParseArgument(args, 1);

			EventLog* pm = new EventLog(s, ln);

			pm->Wrap(args.This());
			return args.This();
		}

		//The log method that node will call.
		//It unwraps the c++ object and call WriteEntry in the _eventLog field
		static Handle<Value> Log(const Arguments& args)
		{
			if (!args[0]->IsString()) {
				return ThrowException(Exception::TypeError(
					String::New("First argument must be the message to log.")));
			}
			
			if (!args[1]->IsString()) {
				return ThrowException(Exception::TypeError(
					String::New("Second argument must be the type of the entry Information/Warning/Error.")));
			}

			gcroot<System::String^> m = ParseArgument(args, 0);
			gcroot<System::String^> t = ParseArgument(args, 1);
			gcroot<System::Diagnostics::EventLogEntryType> logt = (System::Diagnostics::EventLogEntryType)System::Enum::Parse(System::Diagnostics::EventLogEntryType::typeid, t);

			//unwrap the instance! that's crazy
			EventLog* xthis = ObjectWrap::Unwrap<EventLog>(args.This());

			xthis->_eventLog->WriteEntry(m, logt, 1000);

			return Undefined();
		}
	};

	Persistent<FunctionTemplate> EventLog::s_ct;

	extern "C" {
		void NODE_EXTERN init (Handle<Object> target)
		{
			EventLog::Init(target);
		}
		NODE_MODULE(sharp, init);
	}

Some interesting things about this:

 * Node will call always the static methods of the class, the New and the Log.
 * In the statics methods we have to unwrap/wrap the "this" to get/st the real instance of the class (c++ instance).
 * We store the _eventLog instance in a private *non static* field.
 * Arguments args; is like the javascript "arguments" kind-of-array that you have in every javascript function
 * convert v8 javascript values to c++ values, then convert it to .net values. For instance the strings  

# Testing the module

When you generate this project, you will have a "debug" folder *at the same level than the solution* (note that is not the debug folder of the project folder).
There is one important file there, the ".node" file which is a dll than node can talk to.
Now, if you can open a command line prompt and try the stuff with the node [[4]REPL](http://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), but remember that in order to write to the event log you need an elevated prompt, otherwise will happen this:

![2012-04-10_1212.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1212.png)
So, you run cmd.exe as an administrator, go to the solution folder \debug and do this:

![2012-04-10_1216.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1216.png)

Then if you open the event log you will see this:

![2012-04-10_1219.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1219.png)


# Debugging

You can debug your module from visual studio (that's crazy). First you need to be running Visual Studio as an admin, this is not always, it is because we are running the node's REPL as an admin in order to write to the event log.
Once you have done the "require" call in the node REPL, go to the Debug menu of Visual Studio and then "Attach to Process" and look at the node process:

![2012-04-10_1224.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1224.png)

Then you can set breakpoints and this will happen:

![2012-04-10_1230.png](http://joseoncodecom.ipage.com/wp-content/uploads/images/2012-04-10_1230.png)

# TODOs

As you can see here we are executing the eventLog.WriteLog method in the same thread. An standard for this is to open a new thread using "uv". I will explain this in another article later.   

# Credits 
 
 * I have used this guide [[4]example](https://github.com/saary/node.net) from Saar Yahalom as starting point. 

# References

 * [[1] Windows Event Log Js](https://github.com/jfromaniello/windowseventlogjs)
 * [[2] System.Diagnostic.EventLog](http://msdn.microsoft.com/en-us/library/system.diagnostics.eventlog.aspx)
 * [[3] Node.js source code](http://nodejs.org/#download)
 * [[4] Saar Yahalom article](https://github.com/saary/node.net/)