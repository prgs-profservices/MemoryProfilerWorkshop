# MemoryProfilerWorkshop
This repository contains code and artifacts for a Memory Profiler Workshop. 

This has been tested when installed in C:/MemoryProfilerWorkshop.
  PDS .project files should not reflect the physical location, but be aware that changing the physical location of a project in PDS can be problematic since it may be reflected in other PDS artifacts like working sets. It may be necessary to delete and add the project even if the name is the same. (This is based on experience from older versions. Current version may have better handing of this)  

  The PAS section below shows PROPATH with this physical location name. 

The workshop is intended to run on PAS, but this repository only containa PAS files for the PAS instance _ _work_ _ directory.  

# Database
Both the workshop ABL runtime and PAS instance ablapp must be connected to a copy of Sports2020.  

The database should be setup in OEM and started before OEPDS and the PAS instance is started.  

The PAS instance work directory and the ABL projects assumes that the database is setup as follows:   
  Physical Location: C:\db\sports2020    
  Hostname:          localhost  
  Port:              8700   

If PDS is started before this it will start its own multiuser db that then will prevent start of the PAS instance.

I assume that the Physical Location is ignored when using Host and Port, but this is not tested. 

# OEMP PAS instance
Install Memory Profiler.  
__NOTE:__ The PAS instance work files and ABL unit directroy has memoryProfiler config files with _ _report-dir C:\OpenEdge\WRK\oemp\import_ _

The oemp PAS instance should be started before the workshop starts.

# PAS instance
The application has been developed with a PAS instance named _ _workshop_ _. The assumption is that the name does not matter, but this has not been tested.    

Create a PAS developemnt instance. You do not want or need login and/or authentication here. 
Copy the files from the pasinstance-work\work repositry directly into the PAS instance _ _work_ _ directory.  

The application is setup to run in a _ _main_ _ webapp and an ablapp with the same name. Not the ROOT. Deploy the ablapp and webapp.  

The PAS instance ablapp  __MUST__ have the full Application directory in propath! 

__DO NOT SETUP OEPDS to publish to PAS!__  

PAS main ablapp Configuration:
   Agent working directory: ${CATALINA_BASE}/work
   Agent startup parameter: -T "${catalina.base}/temp" -pf ${CATALINA_BASE}/work/workshop.pf
   PROPATH                : C:/MemoryProfilerWorkshop/Application,${DLC}/tty,${DLC}/tty/netlib/OpenEdge.Net.apl                      

The REST test collections are setup to use the following URL http://localhost:8080/main/web/api/. This is controlled in a single _ _BaseUri_ _ environment variable and is assumed to be easy to change, but this has not been tested.

# ABL code
The ABL runtime is built connected to a copy of Sports2020 and PDS and the PAS ablapp must have propath set to the Application directory.   

The repository contains three PSDOE projects: Application, Test and Work. All projects are connected to the sports2020 db.

The assumption is that the Application source can be edited in VSCODE instead of PDSOE. Test has AblUnit code only and Work is for runnung things in the scope of the db and application and may not be useful in VSCODE.   

Advanced (Assumed to not be needed in workshop):
  config/serviceConfig.json has "CheckForNewResources": false. 
  In a dev environment where developers create new classes this will be set to true so that the ServiceManager automaticallyadds these resources to the its cache by generating a new config/resources.json. There is no need to create new classes to resovle the leaks in the workshop. There is also code in the Work project that can genrate config/resources.     

## PDSOE
Setup (recommended)
### Window > Preferences
Window
└─ Preferences  
    ├─ General  
    │  ├─ Appearance  
    │  └─ Workspace  
    ├─ Progress OpenEdge  
    │  ├─ Editor  
    │  ├─ AVM  
    │  └─ Runtime  
    └─ Team  
       └─ Git  
Window
└ General 
├ General
 ├ Editors
  ├ Structured Text Editors
    [V] Show line numbers 
 > Progress OpenEdge 
  > Database Connections
      Connection name: sports2020
      Physical name  : C:\db\sports2020
      Hostname       : localhost
      Port           : 8700
      Autostart      : false         
  > Editor
    Case
     Check radio-set option __Lower__ 
   > Build
     Actions
      [V] Compile on save if required 
     Syntax check:   
      [V] Automatically check syntax 
      Make dure all others are unchecked
  > Startup
    Default starttup parameters: -debugalert -inp 32000 -tok 4096 -rereadnolock -s 200 -mmax 65534   -D 300  -zn  -h 6 -errorstack -cpinternal utf-8 -cpstream utf-8 


### Application 
Has all runtime code. 
### Test
Contains ABL Unit tests. Has propath set to Application. Optional for the workshop.
### Work
Run stuff from here. Has some random working code. Has propath set to Application. Optional for the workshop.
Advanced (Assumed to not be needed in workshop):
  Tools/Generate/launchGenerateResources.p can be run to generate config/resources.json in the Application config directory. Only needed if new BE, DA or DS classes are created and this is not necessary to fix the leaks in the workshop. 
  In a standard project the resources.json are not checked in, but it is checked in here
