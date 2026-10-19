/*------------------------------------------------------------------------------
 File        : DataSource.CustomerDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:09.770-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Core.Error.BadRequestError from propath.

class DataSource.CustomerDS inherits DataSource:

    {schema/customer.i reference-only}

    define public override property EntityName as character init "customers" no-undo get.

    constructor CustomerDS():
        super(buffer Customer:handle).
    end constructor.

    method protected void Bind( input table ttCustomer bind):
    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method override protected void CreateBeginTransValidate( input dataset-handle  phDataset):
        assign ttCustomer.CustNum = next-value (NextCustnum).
    end method.
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        if row-state(ttCustomer) = row-modified and ttCustomer.custNum <> biCustomer.custNum then 
            ThrowBufferError(substitute ("CustNum is readonly. Cannot change Customer Cust Num &1 to &2",biCustomer.CustNum,ttCustomer.custNum),"CustNUm"). 
        
    end method.
    
    
end class.
