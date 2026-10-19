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

using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.QueryPredicate from propath.
using Pmfo.Core.Manager.ServiceManager from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.

class Business.CustomerBE inherits BusinessEntity:

    {schema/customer.i}
    
    {schema/salesrep.i}
    {schema/state.i}
    
    {schema/invoice.i}
    
    define dataset dsCustomer for ttCustomer.

    constructor CustomerBE():
        super(dataset dsCustomer:handle).
    end constructor.
    
    method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateCustomer(dataset-handle phDataset by-reference ). 
    end method.    
   
    method protected void ValidateCustomer(input dataset dsCustomer):
        ValidateUpdate(input table ttCustomer by-reference).
        ValidateDelete(input table ttCustomer by-reference).   
    end method.
    
    /* define ttCustomer as parameter since it may not be the internally defined ttCustomer 
       ttSalesRep and ttState are internal so not paramter needed */ 
    method protected void ValidateUpdate(input table ttCustomer):
        define buffer bSalesRep for ttSalesRep.
        
        // bail if no update - delete validation is handled in ValidateDelete  
        if not can-find(first ttCustomer where row-state(ttCustomer) > 0) then 
            return.
              
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
                        // if there is another salesrep with this region then throw an errpr
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
                        else // if no salesrep exists for region add warning
                            AddWarning(substitute("&1 with Sales Rep '&2' that has Region '&3' and State '&4' which is in Region '&5'",
                                                  GetCustomerInfoForWarning(buffer ttCustomer),
                                                  ttSalesRep.SalesRep,
                                                  ttSalesRep.Region, 
                                                  ttState.State,
                                                  ttState.Region 
                                                  )
                                       ).
                                                         
                    end. // if ttSalesRep.Region <> ttState.Region then 
                end. // country = usa
                else do: 
                    // region can be country if customer.country is not usa
                    if ttSalesRep.Region <> ttCustomer.Country then do:
                        // if there is another salesrep with this region then throw an error
                        find first bSalesRep where bSalesRep.Region = ttCustomer.Country no-error.
                        if avail bSalesRep then                             
                            BufferError(buffer ttCustomer:handle,
                                        substitute("&1. Sales Rep '&2' has Region '&3' does not match Country '&4'",
                                                   GetCustomerInfoForError(buffer ttCustomer),
                                                   ttSalesRep.SalesRep,
                                                   ttSalesRep.Region, 
                                                   ttCustomer.Country
                                                   )
                                        ).
                        else // if no salesrep exists for country add warning
                            AddWarning(substitute("&1 with Sales Rep '&2' that has Region '&3' that does not match Country '&4'",
                                                  GetCustomerInfoForWarning(buffer ttCustomer),
                                                  ttSalesRep.SalesRep,
                                                  ttSalesRep.Region, 
                                                  ttCustomer.Country
                                                  )
                                       ).
                    end. // if ttSalesRep.Region <> ttCustomer.Country 
                end. // not usa
            end. // created to salesrep or state changfed     
        end. // for each ttCustomer where row-state(ttCustomer) > 0:
    end method.     
    
     /* define ttCustomer as parameter since it may not be the internally defined ttCustomer 
        ttSalesRep and ttState are internal so not paramter needed */ 
    method protected void ValidateDelete(input table ttCustomer):
        define variable oInvoiceBE    as IBusinessEntity no-undo.
        define variable oOrderBE      as IBusinessEntity no-undo.
        define variable hOrderTable   as handle no-undo.
        define variable lHasOrders    as logical no-undo.
        define variable oQuery        as IQueryPredicate no-undo.
        
        oInvoiceBE = ServiceManager:CreateBusinessEntity("invoices").
        oOrderBE   = ServiceManager:CreateBusinessEntity("orders").
        
        for each biCustomer where row-state(biCustomer) = row-deleted:
            oQuery = new QueryPredicate("CustNum",QueryOperatorEnum:Eq,biCustomer.CustNum).
                  
            oInvoiceBE:GetData(oQuery,output table ttInvoice). 
            // as of current no need to use ttOrder data TODO?: add list of open orders to message    
            oOrderBE:GetData(oQuery,output table-handle hOrderTable).
            lHasOrders = hOrderTable:has-records.
            
            for each ttInvoice where ttInvoice.CustNum = biCustomer.CustNum:  
                if ttInvoice.amount <= ttInvoice.totalpaid + ttInvoice.adjustment then
                    if lHasOrders = false then 
   /* NEXT! */          next. // ok to delete if no orders    
                    else 
                        ThrowOutstandingOrdersError(buffer biCustomer:handle).
                else 
                    ThrowBufferError(buffer biCustomer:handle,
                                     substitute("Outstanding Unpaid Invoice Exists, cannot delete Customer &1",biCustomer.custnum)).  
            
            end.
            
            if lHasOrders then
                ThrowOutstandingOrdersError(buffer biCustomer:handle).
        end.
        finally:
            empty temp-table ttInvoice.
            if valid-handle(hOrderTable) then 
                delete object hOrderTable.
        end.    
    end method.
    
    method protected void ThrowOutstandingOrdersError(phBiHandle as handle): 
        ThrowBufferError(phBiHandle,
                         substitute ("Open orders exist for Customer &1. Cannot delete.",phBiHandle::CustNum)).  
    
    end method.
    
    method protected character GetCustomerInfoForError(buffer ttCustomer for ttCustomer):
        return substitute ("&1 of &2 failed",
                           BufferUtil:GetRowStateStringPassive(row-state(ttCustomer), true),
                           GetCustomerInfoForMessage(buffer ttCustomer)
                           ).
    end method.     
    
    method protected character GetCustomerInfoForWarning(buffer ttCustomer for ttCustomer):
        return substitute ("&1 is &2",
                           GetCustomerInfoForMessage(buffer ttCustomer),
                           BufferUtil:GetRowStateStringPast(row-state(ttCustomer)) 
                           ).
    end method.     
    
    method protected character GetCustomerInfoForMessage(buffer ttCustomer for ttCustomer):
        // cust num has no meaning for new record
        if row-state(ttCustomer) = row-created then 
            return substitute ("customer '&1'",ttCustomer.name).
        
        return substitute("Customer &1 - '&2'",ttCustomer.Custnum,ttCustomer.name). 
    end method.     
    
    
    // Fetch all data for a table using public name 
    method protected void FetchData(pcService as character, output table-handle phTable):
        define variable oBE      as IBusinessEntity no-undo.
        define variable hDataset as handle no-undo.
        oBE = ServiceManager:CreateBusinessEntity(pcService). 
        oBe:GetData(output dataset-handle hDataset).
        phTable = DatasetUtil:GetBufferByTableSerializeName(hDataset, pcService):table-handle.
    end method.     
    
end class.
