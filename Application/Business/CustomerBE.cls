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
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.QueryPredicate from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Manager.ServiceManager from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.StringUtil from propath.

class Business.CustomerBE inherits BusinessEntity:

    {schema/customer.i}
    
    {schema/salesrep.i}
    {schema/state.i}

    {schema/invoice.i reference-only}
    {schema/order.i reference-only}
    
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
    
   /* define ttCustomer as parameter since the BE supports managing 
       an externally defined ttCustomer table with same schema.  
       ttSalesRep and ttState are internal so no parameter is needed */ 
    method protected void ValidateUpdate(input table ttCustomer):
        define buffer bSalesRep for ttSalesRep.
        
        // bail if no update - delete validation is handled in ValidateDelete  
        if not can-find(first ttCustomer where row-state(ttCustomer) > 0) then 
            return.
              
        // if we do not already have states copy all to the temp-table here  
        if not can-find(first ttState) then
            FetchTable(temp-table ttState:serialize-name, output table ttState).
        
        // Copy to the ttSalesrep defined here 
        FetchTable(temp-table ttSalesrep:serialize-name, output table ttSalesRep).
        
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
    end method. // ValidateUpdate    
    
    /* define ttCustomer as parameter since the BE supports managing 
       an externally defined ttCustomer table with same schema. */ 
    method protected void ValidateDelete(input table ttCustomer):
        var handle hOrderTable, hInvoiceTable.
        var IQueryPredicate oQuery. 
        
        // start the BEs needed to check if related data prevents delete
        var IBusinessentity oInvoiceBE = ServiceManager:CreateBusinessEntity("invoices").
        var IBusinessentity oOrderBE   = ServiceManager:CreateBusinessEntity("orders").
        
        for each biCustomer where row-state(biCustomer) = row-deleted:
            oQuery = new QueryPredicate("CustNum",QueryOperatorEnum:Eq,biCustomer.CustNum).
            
            oInvoiceBE:GetData(oQuery,output table-handle hInvoiceTable).
            AssertPaidInvoices(biCustomer.CustNum, input table-handle hInvoiceTable by-reference). 
            
            oOrderBE:GetData(oQuery,output table-handle hOrderTable). 
            AssertNoOutstandingOrders(biCustomer.CustNum, input table-handle hOrderTable by-reference).
        end.
        finally:
            if valid-handle(hInvoiceTable) then 
                delete object hInvoiceTable.
            if valid-handle(hOrderTable) then 
                delete object hOrderTable.
        end finally.
    end method. //  ValidateDelete
    
    method protected void AssertPaidInvoices(piCustnum as integer, input table ttInvoice):
        var character cUnpaidInvoiceNums.
        
        for each ttInvoice where ttInvoice.CustNum = piCustnum: 
            if ttInvoice.amount > ttInvoice.totalpaid + ttInvoice.adjustment then 
               cUnpaidInvoiceNums = left-trim(substitute("&1,&2",cUnpaidInvoiceNums,ttInvoice.InvoiceNum),",").
        end.
        if cUnpaidInvoiceNums > "" then
            undo, throw new BadRequestError(
                substitute("Customer &1 has unpaid invoice&2: &3 and cannot be deleted.",
                            piCustNum,
                            if num-entries(cUnpaidInvoiceNums) > 1 then "s" else "",
                            StringUtil:GetMessageFromEntries(cUnpaidInvoiceNums))
                           ).
    end method.    
    
    method protected void AssertNoOutstandingOrders(piCustNum as integer,input table ttOrder):
        var character cOrderNums.
        
        for each ttOrder where ttOrder.CustNum = piCustNum:
            cOrderNums  = left-trim(substitute("&1,&2",cOrderNums,ttOrder.OrderNum),",").
        end.
        if cOrderNums > "" then     
            undo, throw new BadRequestError(
                substitute("Customer &1 has existing order&2: &3 and cannot be deleted.",
                            piCustNum,
                            if num-entries(cOrderNums) > 1 then "s" else "",
                            StringUtil:GetMessageFromEntries(cOrderNums))
                           ).  
    end method.
    
    // get customer key value info for error
    method protected character GetCustomerInfoForError(buffer ttCustomer for ttCustomer):
        return substitute ("&1 of &2 failed",
                           BufferUtil:GetRowStateStringPassive(row-state(ttCustomer), true),
                           GetCustomerInfoForMessage(buffer ttCustomer)
                           ).
    end method.     
    
    // get customer key value info for warning
    method protected character GetCustomerInfoForWarning(buffer ttCustomer for ttCustomer):
        return substitute ("&1 is &2",
                           GetCustomerInfoForMessage(buffer ttCustomer),
                           BufferUtil:GetRowStateStringPast(row-state(ttCustomer)) 
                           ).
    end method.     
    
    /* get customer info as string for message
       - used by GetCustomerInfoForError and GetCustomerInfoForWarning */
    method protected character GetCustomerInfoForMessage(buffer ttCustomer for ttCustomer):
        // cust num has no meaning for new record
        if row-state(ttCustomer) = row-created then 
            return substitute ("customer '&1'",ttCustomer.name).
        
        return substitute("Customer &1 - '&2'",ttCustomer.Custnum,ttCustomer.name). 
    end method.     
    
    // Fetch all data for a table using public name 
    method protected void FetchTable(pcService as character, output table-handle phTable):
        var IBusinessEntity oBe = ServiceManager:CreateBusinessEntity(pcService).
        oBe:GetData(output table-handle phTable).
    end method.     
     
end class.
