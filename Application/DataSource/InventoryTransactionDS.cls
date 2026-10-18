/*------------------------------------------------------------------------------
 File        : DataSource.InventoryTransactionDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 08/02/2026 09:49:42.170-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.TimeZoneUtil from propath.

class DataSource.InventoryTransactionDS inherits DataSource:

    {schema/inventoryTransaction.i reference-only}

    define public override property EntityName as character init "inventoryTransactions" no-undo get.

    constructor InventoryTransactionDS():
        super(buffer InventoryTrans:handle).
    end constructor.

    method protected void Bind( input table ttInventoryTransaction bind):
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
    
    method public override character GetDataSourceKeys(phNuffer as handle):
        return "InvTransNum". // No unique key in db! If there are duplicate data in the db then this is a terrible workaround. 
    end method.
    
    method override protected void CreateBeginTransValidate( input dataset-handle phDataset):
        define buffer bInvTransaction for InventoryTrans.
        define variable ILastTransNum as integer no-undo.
        // get last transnum from db
        for each bInvTransaction by bInvTransaction.InvTransNum desc:
            ILastTransNum = bInvTransaction.InvTransNum.
            leave. 
        end.     
        ttInventoryTransaction.InvTransNum = ILastTransNum + 1.
    end method.
        
    // override to manage the timein and timeput date tiem fields not mapped 
    // database fields directly
    method override protected void WriteEndTransValidate( input dataset-handle  phDataset):
        
        if row-state(ttInventoryTransaction) = row-created 
        or ttInventoryTransaction.ItemNum <> biInventoryTransaction.ItemNum then 
        do: 
            find item  no-lock where Item.ItemNum = ttInventoryTransaction.ItemNum no-error.
            if not avail item then 
                BufferError(substitute ("Inventory Transaction Item Num &1 is not valid. Transaction Time Transaction Time &2",
                                         ttInventoryTransaction.ItemNum,
                                         ttInventoryTransaction.TransactionTime
                                        )
                            ). 
        end.
        
        if row-state(ttInventoryTransaction) = row-created 
        or ttInventoryTransaction.OrderNum <> biInventoryTransaction.OrderNUm then 
        do: 
            find Order no-lock where order.OrderNum = ttInventoryTransaction.OrderNum no-error.
            if not avail order then 
                BufferError(substitute ("Inventory Transaction Order Num &1 is not valid. Transaction Time Transaction Time &2.",
                                         ttInventoryTransaction.OrderNum,
                                         ttInventoryTransaction.TransactionTime
                                        )
                            ). 
        end.
        
        if row-state(ttInventoryTransaction) = row-created 
        or ttInventoryTransaction.PONum <> biInventoryTransaction.PONum then 
        do: 
            find PurchaseOrder no-lock where PurchaseOrder.PONum= ttInventoryTransaction.PONum no-error.
            if not avail purchaseOrder then 
                BufferError(substitute ("Inventory Transaction PO Num &1 is not valid. Transaction Time &2.",
                                         ttInventoryTransaction.PONum,
                                         ttInventoryTransaction.TransactionTime
                                        )
                            ). 
        end.
        
        if row-state(ttInventoryTransaction) = row-created 
        or ttInventoryTransaction.WarehouseNum <> biInventoryTransaction.WarehouseNum then 
        do: 
            find Warehouse no-lock where Warehouse.WarehouseNum = ttInventoryTransaction.WarehouseNum no-error.
            if not avail Warehouse then 
                BufferError(substitute ("Inventory Transaction Warehouse Num &1 is not valid. Transaction Time &2.",
                                         ttInventoryTransaction.WarehouseNum,
                                         ttInventoryTransaction.TransactionTime
                                        )
                            ). 
        end.
        
        if row-state(ttInventoryTransaction) = row-created 
        or ttInventoryTransaction.BinNum <> biInventoryTransaction.BinNum then 
        do: 
            find Bin no-lock where Bin.BinNum = ttInventoryTransaction.BinNum no-error.
            if not avail Bin then 
                BufferError(substitute ("Inventory Transaction Bin Num &1 is not valid. Transaction Time &2.",
                                         ttInventoryTransaction.BinNum,
                                         ttInventoryTransaction.TransactionTime
                                        )
                            ). 
        end.
        
        // convert to UTC (GSM)   
        ttInventoryTransaction.TransactionTime = TimeZoneUtil:GetSysTimeFromLocalTime(ttInventoryTransaction.TransactionTime).
        
        findSource(exclusive-lock).
        
        // store as date and time string
        assign
            InventoryTrans.TransDate = date(ttInventoryTransaction.TransactionTime).
            InventoryTrans.TransTime = string(integer(mtime(ttInventoryTransaction.TransactionTime) / 1000),"HH:MM").
        
    end method.
    
    
    method public override void AfterRow(input dataset-handle phDataset):
        define variable dTransDateTime as datetime no-undo.
        //convert to datetime from date and time
        dTransDateTime = 
            datetime(substitute("&1 &2",string(InventoryTrans.TransDate,"99-99-9999"),InventoryTrans.TransTime)).
          
        // convert from UTC (GSM) in database to local time as defined by TimeZoneUtil:TimeZoneName 
        ttInventoryTransaction.TransactionTime = TimeZoneUtil:GetLocalTimeFromSysTime(dTransDateTime).
        super:AfterRow(input dataset-handle phDataset by-reference).
    end method.
 
    
end class.
