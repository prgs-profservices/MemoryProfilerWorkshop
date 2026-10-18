/*------------------------------------------------------------------------------
 File        : DataSource.TimeSheetDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:12.730-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.DateUtil from propath.
using Pmfo.Util.TimeZoneUtil from propath.
using Pmfo.Core.Error.BadRequestError from propath.

class DataSource.TimeSheetDS inherits DataSource:

    {schema/timeSheet.i reference-only}

    define public override property EntityName as character init "timeSheets" no-undo get.

    constructor TimeSheetDS():
        super(buffer TimeSheet:handle).
    end constructor.

    method protected void Bind( input table ttTimeSheet bind):
    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public character GetStringTime(pDatetime as datetime,output pTimeIsPm as logical):
        define variable cString as character no-undo.
        cString = replace(string(interval (pDatetime,date(pDatetime),"seconds"),"hh:mm"),":","").
        if integer(cString) lt 0100 then
            cString = string(integer(cString) + 1200).
        if integer(cString) ge 1300 then do:    
            cString = string(integer(cString) - 1200).
            pTimeIsPm = true.   
        end.
        else if integer(cString) ge 1200 then  
            pTimeIsPm = true.   
            
        if integer(cString) lt 1000 then  
           return " " + cString. 
           
        return cString.

    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).        
    end method.
    
    // override to manage the timein and timeput date tiem fields not mapped 
    // database fields directly
    method override protected void WriteEndTransValidate( input dataset-handle  phDataset):
        define variable cStringIn  as character no-undo.
        define variable cStringOut as character no-undo.
        define variable lIsTimeInPM as logical no-undo. 
        define variable lIsTimeOutPM as logical no-undo.   
        
        findSource(exclusive-lock).
        
        find employee no-lock where employee.empNum = ttTimeSheet.EmpNum no-error.
        if not avail Employee then 
            BufferError(substitute ("Employee Num &1 submitted with Time In &2 and Time out &3 does not exist.",
                                     ttTimeSheet.EmpNum,ttTimeSheet.TimeIn,ttTimeSheet.TimeOut),
                        "EmpNum").
            
        if ttTimeSheet.DayRecorded > ? and ttTimeSheet.DayRecorded <> date(ttTimeSheet.TimeIn) then 
            BufferError(substitute ("Day Recorded for Employee &1 &2 (&3) must match Time In &4. Leave the date empty or correct it.",
                                     employee.FirstName,employee.LastName,employee.empNum,ttTimeSheet.TimeIn),
                        "DayRecorded").
       
        // convert to UTC for storage  
        assign
            ttTimeSheet.TimeIn      = TimeZoneUtil:GetSysTimeFromLocalTime(ttTimeSheet.TimeIn)
            ttTimeSheet.TimeOut     = TimeZoneUtil:GetSysTimeFromLocalTime(ttTimeSheet.TimeOut)
            ttTimeSheet.DayRecorded = date(ttTimeSheet.TimeIn)
            .  
       
        // convert to the legacy split in pm and am time     
        assign 
            cStringIn  = GetStringTime(ttTimeSheet.TimeIn, output lIsTimeInPM)
            cStringOut = GetStringTime(ttTimeSheet.TimeOut, output lIsTimeOutPM) 
            .
        
        if lIsTimeInPM then 
           TimeSheet.PMTimeIn = cStringin.
        else     
           TimeSheet.AMTimeIn = cStringin.
        if lIsTimeOutPM then 
           TimeSheet.PMTimeOut = cStringOut.
        else     
           TimeSheet.AMTimeOut = cStringOut.
        
        
    end method.
    
    
    method public override void AfterRow(input dataset-handle phDataset):
        define variable cTimeIn as character init "00:00" no-undo.  
        define variable cTimeOut  as character no-undo.
        define variable dDateOut as date  no-undo.  
        define variable iSec as integer no-undo.
        
   
        if TimeSheet.AMTimeIn > "" then do:
            if TimeSheet.AMTimeIn begins "12" then
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(substring(TimeSheet.AMTimeIn,4))). 
            else
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.AMTimeIn)). 
            cTimein = string(iSec,"HH:MM"). 
        end.
        else if TimeSheet.PMTimeIn > "" then do:
            if TimeSheet.PMTimeIn begins "12" then
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeIn)).
            else     
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeIn) + 1200). 
            cTimein = string(iSec,"HH:MM"). 
        end.
        
             
        if TimeSheet.AMTimeOut > "" then do:
            if TimeSheet.AMTimeOut begins "12" then
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(substring(TimeSheet.AMTimeOut,4))). 
            else
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.AMTimeOut)). 
            cTimeOut = string(iSec,"HH:MM"). 
        end.
        else if TimeSheet.PMTimeOut > "" then do:
            if TimeSheet.PMTimeOut begins "12" then
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeOut)).
            else     
                iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeOut) + 1200). 
            cTimeOut = string(iSec,"HH:MM"). 
        end.
        else
            cTimeOut = substitute("&1:00",integer(TimeSheet.RegularHours) + integer(substring(cTimein,1,2))).
        
        if cTimeOut lt cTimeIn then dDateOut = TimeSheet.DayRecorded + 1.
        else dDateout = TimeSheet.DayRecorded.
      
        ttTimeSheet.TimeIn = 
           datetime(substitute("&1 &2",string(TimeSheet.DayRecorded,"99-99-9999"),cTimein)).
        ttTimeSheet.TimeOut = 
           datetime(substitute("&1 &2",string(dDateout,"99-99-9999"),cTimeout)).
        
        // convert from UTC time in db to time zone in TimeZoneUtil
        ttTimeSheet.TimeIn  = TimeZoneUtil:GetLocalTimeFromSysTime(ttTimeSheet.TimeIn).
        ttTimeSheet.TimeOut = TimeZoneUtil:GetLocalTimeFromSysTime(ttTimeSheet.TimeOut).
                
        super:AfterRow(input dataset-handle phDataset).
    end method.
    
end class.
