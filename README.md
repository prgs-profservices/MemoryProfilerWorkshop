# MemoryProfilerWorkshop
This repository contains code and artifacts for a Memory Profiler Workshop where students runs an application that has memory leaks and uses the Memory Profiler to find and fix the leaks in the application. 

The workshop application is intended to run on PAS connected to a copy of Sports2020. __The PAS instance ablapp must have the Application project directory in PROPATH.__ This repository contains the .pf with startup parameters for the PAS instance and the memory profiler .config file referenced by the .pf that should be copied to the worrk directory of the PAS instance. 

The assumption is that a REST tool is used to run the services in the application and this repository contains environment and collections files that cshould be loaded into Postman or Bruno REST test tools.   

This has been tested when installed in C:/MemoryProfilerWorkshop. The only known dependency of the physical location is that the PAS instance ablapp's PROPATH should point to the Application project with full path.    

The Memory Profiler filer oemp PAS instance various components needed for the workshop are discussed below.

## Database 
Create a database by copying the Sports2020 database in the Progress install. The workshop setup assumes the database is located in C:\db. The physical location is assumed to be ignored when defining Host and Port, but this is not tested. 

The ABL projects in this repository has the database setup as follows.  
Physical Location: __C:\db\sports2020__        
Hostname:          __localhost__     
Port:              __8700__       

The database should be started before the PAS instance and PSDOE is started. It is recommended to setup a database resource for the database with these properties. This can be used to configure it to AutoStart. Even if there is no need to stop and start it is probably a good idea to make it easy to start by the students. 

### Optional
run import_customers.p in the Work project to load customers with utf-8 characters (Mostly french/canadian). Note that there is currently no need to do this and students will not have time to look very closely at the data, but the workshop has a _hidden agenda_ to show use of utf-8. See Hidden Agenda section below.

## Memory Profiler Web App and oemp PAS instance 
Install Memory Profiler WITH default port and location for the PAS instance. 

__NOTE:__ The PAS instance _work_ files and ABL unit directory has MemoryProfiler config files with _report-dir C:\OpenEdge\WRK\oemp\import_

The oemp PAS instance can be started once before the Memory Profiler tool is used and can/should be kept running all the tiem. 

It is recommended to prepare a bookmark in OEM for the web app to allow the students to start it quickly.  

## PAS instance
The workshop PAS instance must be created before the workshop starts. 

The workshop demonstrates use of a local PAS __development__ instance. Make sure to avoid login and/or authentication for this. The application has been developed with a PAS instance named _workshop_. The assumption is that the PAS instance name is irrelevant for the setup, but this has not been tested.

Copy the files from the __pasinstance-work\work__ directory directly into the PAS instance _work_ directory.  

The workshop is setup to run in a _main_ webapp. Deploy an webapp and ablapp with this name.

The PAS instance ablapp  __MUST__ have the full Application directory in propath! __DO NOT SETUP PDSOE TO PUBLISH TO PAS!__  

### PAS main ablapp configuration:  
The working directory is default. The Agent startup parameter is edited to have a -pf with database connection and startup parameters including the memory propfiler setup. The PROPATH is changed to point to the Application. The Session startup has the bootstrap needed to start a ServiceManager and SessionManager and add them to the CCS static  Application.

Agent working directory  : __${CATALINA_BASE}/work__  
Agent startup parameter  : __-T "${catalina.base}/temp" -pf ${CATALINA_BASE}/work/workshop.pf__  
PROPATH                  : __C:/MemoryProfilerWorkshop/Application,${DLC}/tty,${DLC}/tty/netlib/OpenEdge.Net.apl__                        
Session startup procedure: __Core/Startup/sessionstartup.p__ 

__NOTE:__ The REST test collections are setup to use the following URL http://localhost:8080/main/web/api/. This is controlled in a single _BaseUri_ environment variable and is assumed to be easy to change, but this has not been tested.

## ABL code 
The workshop was developed in PDSOE and the assumption is that the students use PDSOE when they fix the memeory leaks, but the assumption is that the Application source can be edited in VSCODE instead of PDSOE. It is unclear if the Test project and Work projects are useful in VSCODE, but these are optional projects.   

The repository contains three PSDOE projects that can be imported as-is to PDSOE. 

### Projects 
All projects are connected to the sports2020 database. See 

#### Application 
The Application project has all source code and the students will fix the leaks in the code. 

It is important that the physical location of this project is referenced in PROPATH for the workshop PAS instance and that PDSOE is not setup tp deploy to PAS, so that the fixes will be picked immediately when running from the PAS REST tool. There is only one known fix that needs a PAS restart.   

##### Test
This project is optional for the workshop. See summary at the end of this section.

The project contains ABL Unit tests prepared to run read and update to the same classes as the REST tool. This project propath is set to the Application. 

The intention is that the students can test and/or debug here and the project contains a Memory Profiler config file that can be added to the Launch Configuration Startup tab for individual tests as follows: 
Additional startup parameters: __-memoryProfiler MemProfConfig.config__ 

Note that the Memory Profiler _PreCleanup snapshot from ABLUnit does not reflect memory as it would be present after a PAS request. ALso note that the _Exit snapshot has a dataset and temp-tables that are from the compile xref that the ABL Unit runs. Adding one or more test methods that invokes MemoryProfiler:TakeSnapShot("sometestinfo") will produce snapshots comparable to what would be seen after a PAS request, but some of the tests runs so fast that multiple snapshots before and after the predefined test methods will not show up in the Memory Profiler graph since they have the same time stamp. This can be worked around using a PAUSE statment.            

###### Summary
The experience from one 3 hour workshop is that students do not have time to use this. The fact that Memory Profiler report files from Progress version 12.8.12 can be uploaded to the Memory Profiler without stopping PAS means that the students can test their fixes directly in the REST tool immediately. __NOTE:__ The 12.8.12 patch installed on top of an older Progress version did not show this behavior. The assumtion/guess is that the reason is that the oemp PAS instance was old and that it needs to be reinstalled or refreshed/reset somehow.      

##### Work
This is also optional for the workshop. The project has propath set to Application and is intended to be used if one wants to run a regular program or class that uses the Application classes and/or database. It contains some incidental programs that has for each, and display for some tables.

### PDSOE > Window > Preferences
The following shows some of the recommended Window Preferences for the workshop 

#### General > Editors > Structured Text Editors
[V] Show line numbers 

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

The parameters that have number values are based on long time use of PDSOE, but may not necessarilty be optimal.   

### Compilation 
It is typically not necessary to recompile code since the PDSOE is setup to compile on save.

If the temp-table definition in one of the incldues in the schema is changed both the coresspoinffng *BE and *DS needs to be recompiled. 

#### Compilation bug 
If the Application project is recompiled there is a bug that prevents Pmfo.Core.Manager.Manager from being comppiled. Opening the file (from the Problem View) and right-clikc and select _compile_ wioll fix this. There has been cases where it seems necessary to compoile twice. The assumption is that this problem has to do with the static reference to the StartupManager in thois code. If this is not compiled successfully it may cause weird errors at runtime. 
DISCLAIMER: The problem is not researched.  

#### Bootstrapping, Source Discovery and Factory:
This information is not needed when running the workshop as-is and is assumed to only be relevant if new concrete classes are added to Application project Business, DataAcess or DataSource directories. 




in prinmciple only relvabut could be useful if changing and specifically if or extending the examples   

Tools/Generate/launchGenerateResources.p can be run to generate config/resources.json in the Application config directory. Only needed if new BE, DA or DS classes are created and this is not necessary to fix the leaks in the workshop. 
In a standard project the resources.json are not checked in, but it is checked in here


### Advanced (Assumed to not be needed in workshop):  
  config/serviceConfig.json has "CheckForNewResources": false.   
  In a dev environment where developers create new classes this will be set to true so that the ServiceManager automatically adds these resources to its cache by generating a new config/resources.json and loading it. There is no need to create new classes to resovle the leaks in the workshop. There is also code in the Work project that can generate config/resources.json. 
