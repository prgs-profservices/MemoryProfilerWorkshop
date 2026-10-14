
/*------------------------------------------------------------------------
    File        : generateResources.p
    Purpose     : Generate a json file with resource information for the 
                  ServiceManager.  
    Syntax      : run Tools/Generate/launchGenerateResources.p. 
                  This is intended to and works best when run from 
                  the launchGenerateResources.p in the work project with 
                  propath pointing to the Pmfo framework and source in application, 
                  datasource and dataaccess directories in many or one project  
    Author(s)   : hdaniels
    Created     : Wed May 26 07:43:35 EDT 2021
    Notes       : The data is generated from r-code (or source) using
                  DataAdminManager() to get tables for all connected DBs
                  The NameService MUST resolve a unique public name from  
                  database table name and lookup table name/key in order to 
                  create datasource records of type "Table" and "CodeTable for 
                  BE temp-tables that does NOT have a physical <classname>DS.    
  ---------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Pmfo.Repository.Business.ResourceBE from propath.
using Pmfo.Core.Manager.StartupManager from propath.
using Pmfo.Util.FileUtil from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.

//using Pmfo.Core.Common.IWarningMessageTableHolder from propath.
define variable cDir as character no-undo.
define variable cFile as character no-undo.
define variable oResourceBe as ResourceBE   no-undo.

{Pmfo/Repository/Business/defs/resources-dataset.i} 
 
if not FileUtil:IsDirectory(StartupManager:ConfigDirectory) then 
   undo, throw new IllegalOperationError(subst('ServiceManager:ConfigDirectory "&1" is not a valid directory in propath',StartupManager:ConfigDirectory)).
 
// create an empty resources.json if non exists. 
// the instance startup will start its own resourceBE which needs resources.json                
file-info:file-name = StartupManager:ConfigDirectory.
cDir = file-info:full-pathname.
cFile = FileUtil:AppendToPath(cDir,"resources.json").
if search(cFile) = ? then do:
    create ttentity. // need some data to generate some content
    ttEntity.Resource = "resources".
    dataset dsResources:write-json("file",cFile,yes,?,no,yes). 
end. 
oResourceBe = new ResourceBE(). 
oResourceBE:ReadFromSourceAndCacheData().
return "0". // PCT needs this to detect a successful run 