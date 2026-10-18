/*------------------------------------------------------------------------------
 File        : Business.CustomerBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:09.790-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.TableUtil from propath.
using Pmfo.Core.BusinessLogic.DatasetBuilder from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Progress.Profiler.MemoryProfiler from propath.

class Business.CustomerBE inherits BusinessEntity:

    {schema/customer.i}
    
    {schema/salesrep.i}
    {schema/state.i}
    
    
    define dataset dsCustomer for ttCustomer.

    constructor CustomerBE():
        super(dataset dsCustomer:handle).
    end constructor.
    
    method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateCustomer(dataset-handle phDataset by-reference ). 
    end method.    
   
    method protected void ValidateCustomer(input dataset dsCustomer):
        define buffer bSalesRep for ttSalesRep.
        
        // if we do not already have states copy all to the temp-table here  
        if not can-find(first ttState) then
            FetchData(temp-table ttState:serialize-name, output table ttState).
        
        // Copy to the ttSalesrep defined here 
        FetchData(temp-table ttSalesrep:serialize-name, output table ttSalesRep).
        
        for each ttCustomer where row-state(ttCustomer) > 0:
            if row-state(ttCustomer) = row-created 
            or ttCustomer.SalesRep <> biCustomer.SalesRep
            or ttCustomer.State <> biCustomer.State then 
            do:
                
                find ttSalesRep where ttSalesRep.SalesRep = ttCustomer.Salesrep no-error.
                if not avail ttSalesRep then 
                    BufferError(buffer ttCustomer:handle,
                                substitute("&1. Sales Rep '&2' is not valid",
                                           GetCustomerInfoForError(buffer ttCustomer),
                                           ttCustomer.SalesRep 
                                           ),
                                "SalesRep").
                
                if ttCustomer.Country = "USA" then 
                do:
                    find ttState where ttState.State = ttCustomer.State no-error.
                
                    if not avail ttState then 
                        BufferError(buffer ttCustomer:handle,
                                   substitute("&1. State '&2' is not valid",
                                               GetCustomerInfoForError(buffer ttCustomer),
                                               ttCustomer.State 
                                             ),
                                   "State").
                    if ttSalesRep.Region <> ttState.Region then 
                    do: 
                        // if there is a salesrep with this region then throw an errpr
                        find first bSalesRep where bSalesRep.Region = ttState.Region no-error.
                        if avail bSalesRep then                             
                            BufferError(buffer ttCustomer:handle,
                                        substitute("&1. Sales Rep '&2' has Region '&3' while 'State '&4' is in Region '&5'",
                                                   GetCustomerInfoForError(buffer ttCustomer),
                                                   ttSalesRep.SalesRep,
                                                   ttSalesRep.Region, 
                                                   ttState.State,
                                                   ttState.Region 
                                                   
                                                   )
                                        ).
                                                         
                    end.
                end. // country  usa
                else do:
                    if ttSalesRep.Region <> ttCustomer.Country then do:
                        // if there is a salesrep with this region then throw an errpr
                        find first bSalesRep where bSalesRep.Region = ttCustomer.Country no-error.
                        if avail bSalesRep then                             
                            BufferError(buffer ttCustomer:handle,
                                        substitute("&1. Sales Rep '&2' Region '&3' does not match Country '&4'",
                                                   GetCustomerInfoForError(buffer ttCustomer),
                                                   ttSalesRep.SalesRep,
                                                   ttSalesRep.Region, 
                                                   ttCustomer.Country
                                                   )
                                        ).
                        
                     
                     
                    end.
                end. // not usa
            end. // created to salesrep or state changfed     
        end.
    end.
    
    method protected character GetCustomerInfoForError(buffer ttCustomer for ttCustomer):
        define variable cOperation as character no-undo.
        // cust num has no meaning for new record
        if row-state(ttCustomer) = row-created then 
            return substitute ("Create of customer '&1' failed",ttCustomer.name).
        if row-state(ttCustomer) = row-modified then 
            return substitute ("Update of customer &1 - '(&2)' failed",ttCustomer.Custnum,ttCustomer.name).
        // should not get here.. but just return something    
        return substitute("Customer &1 - '(&2)'",ttCustomer.Custnum,ttCustomer.name). 
    end method.     
    
    // Fetch all data for a table using public name 
    method protected void FetchData(pcService as character, output table-handle phTable):
        define variable oBE      as IBusinessEntity no-undo.
        define variable hDataset as handle no-undo.
        oBE = ServiceManager:CreateBusinessEntity(pcService). 
        oBe:GetData(output dataset-handle hDataset).
        phTable = DatasetUtil:GetBufferByTableSerializeName(hDataset, pcService):table-handle.
    end method.     
   
    method public void TakeSnap() :
        MemoryProfiler:TakeSnapShot("AfterCustomer").
    end method.      
       
end class.
