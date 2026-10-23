# MemoryProfilerWorkshop
This repository contains code and artifacts for a Memory Profiler Workshop where students run a PAS application that has memory leaks and uses the Memory Profiler to find and fix the leaks in the application. 

The workshop application is intended to run on PAS connected to a copy of Sports2020.  
__The PAS instance ablapp must have the Application project directory in PROPATH.__ 

This repository contains the _.pf_ with startup parameters for the PAS instance and the memory profiler _.config_ file referenced by the _.pf_ to be copied to the PAS instance _work_ directory. 

The assumption is that a REST tool is used to run the services in the application and this repository contains environment and collections files that should be loaded into _Postman_ or _Bruno_ REST test tools for this purpose.

This has been tested when installed in _C:/MemoryProfilerWorkshop_. The only known dependency of the physical location is that the PAS instance ablapp's PROPATH should point to the Application project with full path.    

The sections below discuss both the content of this Repository as well as the services that need to be prepared to run the workshop.

## Database 
Create a local database by copying the Sports2020 database in the Progress install. The workshop setup assumes the database is located in _C:\db_. The physical location is assumed to be ignored when defining Host and Port, but this is not tested. 

Setup a database service in OEM with the following properties:  
Physical Location: __C:\db\sports2020__        
Hostname:          __localhost__     
Port:              __8700__       

The database should be started before the PAS instance and PSDOE is started. Even if the database only need to be started once, it is likely a good idea to make it easy to both stop and start the database for the students. It is probably also a good idea to set it up to Auto Start. (Not tested in the workshop)

The ABL projects in this repository has the database connection setup with the same name, host and port.   

The sports2020 database has triggers and table validations defined in the schema. Many of these triggers have UI messages or they are inflexible and difficult to make work in modern code,  subsequently the _Application_ project (discussed below) has a _sports2020trgs_ directory with all the .p programs referenced in the schema where all fucntionality has been removed. Most of the functionality that they provided have been implemented in the workshop Business Entoties or Data Sources.         

## Memory Profiler Web App and oemp PAS instance 
Install the Memory Profiler by following the instruction in Progress documentation. It is recommended to accept the default port and location for the oemp PAS instance. 

__NOTE:__ The PAS instance _work_ files and ABL unit directory has MemoryProfiler config files with _report-dir C:\OpenEdge\WRK\oemp\import_ which is in the default PAS install directory. 

The oemp PAS instance must be started before the Memory Profiler tool is used and should be kept running all the time. 

It is recommended to prepare a bookmark for the web app _http://localhost:8880/_ in the browser used to launch OEM to allow the students to start this quickly.  

## PAS instance
The workshop PAS instance must be created before the workshop starts. 

The workshop demonstrates use of a local PAS __development__ instance. Make sure to avoid login and/or authentication for this. The application has been developed with a PAS instance named _workshop_. The assumption is that the PAS instance name is irrelevant for the setup, but this has not been tested.

Copy the files from the __pasinstance-work\work__ directory directly into this PAS instance _work_ directory.  

The workshop is setup to run in a _main_ webapp. Deploy a webapp with an ablapp where both has this name. 

The PAS instance ablapp  __MUST__ have the full Application directory in propath! __DO NOT SETUP PDSOE TO PUBLISH TO PAS!__  

### PAS main ablapp configuration:  
The working directory shown below is default. 

The agent startup parameter is edited to have a _-pf_ startup parameter pointing to the _workshop.pf_ that should be copied from this repository as described in the PAS instance section above. This _.pf_ has the database connection with host and port as described in the database section above and also includes the -MemoryProfiler option pointing to the memory profiler config file _MemProfConfig.config_ that also should be copied to the work directory together with the _workshop.pf_ file. 

The PROPATH is changed to point to the Application. 

The session startup has a procedure that will bootstrap the ServiceManager and SessionManager by adding them to the CCS static Application class. 

Agent working directory  : __${CATALINA_BASE}/work__  
Agent startup parameter  : __-T "${catalina.base}/temp" -pf ${CATALINA_BASE}/work/workshop.pf__  
PROPATH                  : __C:/MemoryProfilerWorkshop/Application,${DLC}/tty,${DLC}/tty/netlib/OpenEdge.Net.apl__                        
Session startup procedure: __Core/Startup/sessionstartup.p__ 

__NOTE:__ The REST test environement and collections are setup to use the following URL http://localhost:8080/main/web/api/. This is controlled in a single _BaseUri_ environment variable and is assumed to be easy to change, but this has not been tested.

## REST test tool
The REST tool has a central role in the workshop. 

The workshop was developed with Postman while Bruno was setup in the VMs used in the first workshop. 

The files in the __postman-data__ directory should be imported to the REST tool before the workshop starts. 

Note that _Postman_ licensing rules may prohibit preloading the enviroment and collections in VMs for multiple users. (This is based on copilot AI info).    

Bruno has a simpler UI with one caveat when having nested collections like the workhop has; If you run one of the child collections and then navigate to a parent collection to run that, it will default to run the last executed run of the child or grand child. This can easily be resolved by pressing a reset button that will cause  Bruno to reset to the actual collection, but this is easy to overlook when using Bruno for the first time. 

### Collections
There are 3 test collections. The reason for the multiple collections is to make it easier to split the workshop into multiple excercises. 

#### Read data collections
This collection executes GET request for all (most?) services/tables in the application. The leaks that are encountered here are easy to fix except for one Large Object leak caused by a MEMPTR that is stored in a static class property intended to stay in memory during the session. This is in itself not a problem, but unless the size is set to 0 before Progress is shutdown it will remain in memory forever (as shown in the _Exit tag). There is no static destructor so there is no place or event suited to set size to 0 programatically before shuitdown. This is thus an interesting challenge but it may take some time to find a fix. The assumption is that the students has a more immersive experience if they fix this (or try to), without too much information upfront. This leak will show up also after running the Update collection, so the work to fix this can be postponed to the end of the workshop.     

#### Update data collections
This collection executes POST and DELETE request for most services/tables in the application. Some of the leaks that are encountered here are more complicated. 

There is one class level leak caused by two classes having cross references that prevents garbage collection. This needs to be fixed before the other leaks since a class leak will cause objects owned by these classes to shopw up inm the snapshots, which is misleading since they will be deleted when the cross refermnce is eliminated.  

__NOTE__ It is recommended to always run the corresponding DELETE if one runs a POST request test individually. Some of the tests have hard coded keys in the input data  and will fail if run again unless the records created by a previous POST are not deleted. The DELETE request uses the output from the previous POST, so this can be done as a separate run. Most of the tables have sequences and can be run many times without deleting the outcome.

#### Xtra collections
This is a bonus collection mainly intended to be introduced if all attendeees are able to fix all leaks above before the workshop is over. This leak is assumed to be  easy to identify, but the fix is not straghforward. 

## ABL code 
The workshop was developed in PDSOE and the assumption is that the students use PDSOE when they fix the memory leaks. The assumption is that the Application source can be edited in VSCODE instead of PDSOE. It is unclear if the Test project and Work projects are useful in VSCODE, but these are optional projects.   

The repository contains three PSDOE projects that can be imported as-is to PDSOE. 

### Projects 
All projects are connected to the sports2020 database. 

#### Application 
The Application project has all source code and the students will fix the leaks in the code. 

It is important that the physical location of this project is referenced in PROPATH for the workshop PAS instance and that PDSOE is not setup tp deploy to PAS. This ensures that the fixes can be picked immediately when running from the PAS REST tool. There is only one known fix that needs a PAS restart.   

##### Test
This project is optional for the workshop. See summary at the end of this section.

The project contains ABL Unit tests prepared to run read and update to the same classes as the REST tool. This project propath is set to the Application. 

The intention is that the students can test and/or debug here. The project contains a Memory Profiler config file that can be added to the Launch Configuration Startup tab for individual tests as follows: 
Additional startup parameters: __-memoryProfiler MemProfConfig.config__ 

Note that the Memory Profiler _PreCleanup snapshot from ABLUnit does not reflect memory as it would be present after a PAS request. ALso note that the _Exit snapshot has a dataset and temp-tables that are from the compile xref that the ABL Unit runs. Adding one or more test methods that invokes MemoryProfiler:TakeSnapShot("sometestinfo") will produce snapshots comparable to what would be seen after a PAS request, but some of the tests runs so fast that multiple snapshots before and after the predefined test methods will not show up in the Memory Profiler graph since they have the same time stamp. This can be worked around using a PAUSE statment.            

###### Summary
The experience from one 3 hour workshop is that students do not have time to use the ABL Unit tests. The fact that Memory Profiler report files from Progress version 12.8.12 can be uploaded to the Memory Profiler without stopping PAS means that the students can test their fixes directly in the REST tool immediately.

##### Work
This is also optional for the workshop. 

The project has propath set to Application and is intended to be used if one wants to run a regular program or class that uses the Application classes and/or database. It contains some incidental programs that has for each, and display for some tables.

### Project Explorer - Filters 
Rgiht clicking the Filter icon on the top right of the Project Explorer brings up the Filters and Customization dialog. It can be useful to uncheck the .r in particular if the project is setup with source and r-code together as in this case.     

### Problems View - Filters 
Rgiht clicking the Filter icon on the top right of the Problems View brings up the Filters dialog. It can be helpful to ensure that the Error/Warnings on Project Configuration has the radio option for _Scope on elements in selected projects_ selected. This ensures that you can navigate to folders in the Project View and only see the propblems that applies for that foilder. This may not make a big difference in this workshop that does not have a lot of code, but it can still be useful to see if an error in framework code applies to the Business or DataSource folders for the few cases where the fix are best done in the framework.  

### PDSOE > Window > Preferences
The following shows some of the recommended PSDOE Window Preferences for the workshop. (Obviously not applicable if Visual Studio is used instead.) 

Some of these are important while others are assumed to provide optimal behavior while editing the code. The database connection must match the started database. The database is utf-8 so make sure we can handle all data at run time. The workspace settings are useful for the optional ABLUnit tests since it will ensure that the respoinses serialized as JSON show up in the Project Explorere. It may also be useful to see if is r-code  if the Project Explorer Filter and Customization has been changed to show files with .r extension. It is unclear when it would make sense to NOT refresh the project view automatically.  

#### General > Editors > Structured Text Editors
[V] Show line numbers 

#### General > Workspace
[V] Refresh using native hooks or polling 
[V] Refresh on access 

#### Progress OpenEdge > Database Connections
Connection name: __sports2020__       
Physical name  : __C:\db\sports2020__    
Hostname       : __localhost__    
Port           : __8700__  

#### Progress OpenEdge > Editor
Case  
Check radio-set option __Lower__ 

#### Progress OpenEdge > Editor > Build
Actions  
[V] Compile on save if required  
Syntax check:     
[V] Automatically check syntax   
Make sure all others under syntax check are unchecked

#### Progress OpenEdge > Startup 
Default starttup parameters:__-debugalert -inp 32000 -tok 4096 -rereadnolock -s 200 -mmax 65534 -D 300  -zn -h 6 -errorstack -cpinternal utf-8 -cpstream utf-8__ 

The parameters that have number values are based on long time use of PDSOE but may not necessarilty be optimal. The -h number of database connections is likely too high, but keep in mind that it also includes the SQL connection if that is defined for a database. 

### Compilation 
It is typically not necessary to recompile code manually if  the PDSOE is setup to compile on save as shown in the preferences section above.

If the temp-table definition in one of the includes in the _schema_ directory is changed, both the corresponding *BE and *DS need to be recompiled. 

#### Compilation issue
If the Application project is recompiled the  _Pmfo.Core.Manager.Manager_ may fail to compile. This assumption is that this can be avoided by cleaning the project before it is compiled (Menu Project > Clean). It can also be fixed by  opening the file (i.e. from the Problem View) and right-click and compile it (right-click  _compile_.). 

It is not known if this problem exists when r-code and source are in separate directories.  

--- 
The information below is not needed when running the workshop as-is and is assumed to only be relevant if new concrete classes are added to the Application project's Business, DataAccess or DataSource directories.  
---

### Bootstrapping 
The framework implements a ServiceManager that extends and implements the CCS IServiceManager. It serves as the factory to start classes based on public names for external requests as well as internally. A static StartupManager that also extends CCS is the central mechanism to bootstrap managers based on the _config/startup.json_. The managers are added to the static _Ccs.Common.Application_. 

The PAS instance is setup with session startup procedure _Core/Startup/sessionstartup.p_ that calls the StartupManager:Instance that executes this bootstrapping. 
In addtion the classes inherits from a DataService class that has a static constructor that performs the same bootstrapping if _Ccs.Common.Application:StartupManager_ is not valid yet. This allows these classes to run outside of PAS and still use the ServiceManager as a factory to invoke other classes. The ABLUnit tests that runs Business Entities inherits _Tools/Test.TestBase_ that extends this DataService. 

### Factory and source discovery
The ServiceManager caches all named services in a dataset with ttEntity, ttDataAccess and ttDataSource temp-tables at runtime. This dataset is persisted in a _config/resources.json_, but this is a persisted cache as the information about the classes is obtained by reading the source directories and starting the classes. The purpose of the json is to minimize the need to read and start the classes. In production the _config/resources.json_ is typically generated once as part of the build. In development the ServiceManager will typically refresh the _config/resources.json_ and reload the dataset if one of the observed directories; Business, DataAcces or DataSource has changes. The decision to check if a refresh is needed is controlleed by the _config/serviceConfig.json_ _CheckForNewResources_ property, which is used to set the same named property in the ServiceManager.  
 
In this workshop this property is set to _false_ since there is no need to create new named classes as part of the task to fix memory leaks.  

The _Tools/Generate/launchGenerateResources.p_ can be run to generate a fresh _config/resources.json_ in the Application config directory if the _CheckForNewResources_ is false.  

There are some drawbacks of having the _CheckForNewResources_ property set to _true_. 
1. In a very large application the json in memory would sometimes get corrupted on Windows. Possibly due to the fact that changes are added to the existing data. The problem does not exsits when generating from scracth. This is assumed to be core bug, but every attempt to duplicate the bad behavior has failed. 
2. In some versions oif Progress the load of a class crashes when executed immediately after a new class has been saved. This was worked around by adding a message whose only purpose was to stop the execution. (A pause would likely also work). This is also assumed to be a bug, but in this case it may be a filesystem limitation. This can be duplicated, but the crash never occurs at the same place. I.E. It does not necessarily crash when starting the  new class, but sometime after.      
3. If executed with code that does not compile in source directories the resources are not properly loaded to the Service Manager. THis is typically easy to fix by fixing the bad code. It is also likely easy to improve the behavior, but since we never want to have bad source this has not been done. 

The benefits of setting _CheckForNewResources_ true in a real development scenario where new classes are added daily, far outweights these drawbacks. Also note that so far problem 1 and 2 have not been observed in version 12.8. There is thus reason to hope that at least problem 2 is gone. Since problem 1 is more sporadic there is not enough real time usage yet to tell.  