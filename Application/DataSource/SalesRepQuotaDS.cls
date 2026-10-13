/*------------------------------------------------------------------------------
 File        : DataSource.SalesRepQuotaDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   :  
 Created     : 08/032026  
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using OpenEdge.Core.StringConstant from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.QueryBuilder.QueryBuilder from propath.
using Pmfo.Core.BusinessLogic.GetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IQueryDefinition from propath.
using Pmfo.Core.BusinessLogic.QueryDefinition from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryGroup from propath.

class DataSource.SalesRepQuotaDS inherits DataSource:

    {schema/salesRepQuota.i reference-only}

    define public override property EntityName as character init "salesRepQuotas" no-undo get.
    
    define protected variable GetRequest as IGetDataTableRequest no-undo.
    define protected variable FirstPageMonth as integer no-undo.
   
    constructor SalesRepQuotaDS():
        super(buffer SalesRep:handle).
    end constructor.

    method protected void Bind( input table ttSalesRepQuota bind):
    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("Before-fill","BeforeFill").
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
   
    // override to ignore 
    method protected override void CreateSaveSource(phBuffer as handle, pcFieldMap as character):
    end method.
       
    // override to ignore 
    method public override void FindSourceForUnmodifiedRow().
       // FindSource(exclusive-lock).
    end method. 
    
    method public override character GetDataSourceKeys(phNuffer as handle):
        return "SalesRep,Month". // No unique key in db 
    end method.
    
    // override to track request for BEforeFill
    method protected override handle extent GetBufferHandles(pRequest as IGetDataTableRequest,pParentRequest as  IGetDataTableRequest):
        GetRequest = pRequest.              
        FirstPageMonth = 0.  //flag for paging
        return super:GetBufferHandles(pRequest,pPArentRequest).                                                                       
    end method.   
        
    // currently save is managed by salesrep
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        undo, throw new NotImplementedError("Save using SalesRepQuotaDS").
    end method.    
    
    // currently delete is managed by salesrep
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        undo, throw new NotImplementedError("Delete using SalesRepQuotaDS").
    end method.
    
    /* override to grab first predicate that has salesrep from paging context  
       and pass to super tso that startids is set to the salesrep 
       log month in FirstPageMonth property - cannot pass month to super since it is not in salesrep    */    
    method protected override void PreparePaging(pRequest as IGetDataTableRequest, pQueryBuilder as QueryBuilder) :
        define variable pSalesReprequest  as IGetDataTableRequest no-undo.
        define variable oMonthPredicate   as IQueryPredicate no-undo.
        define variable oContextQuery     as IQueryGroup no-undo.
        
        if valid-object(pRequest:PagingContextEntry) then 
        do:
            pSalesReprequest = new GetDataTableRequest(pRequest:TableName).
            oContextQuery = cast(pRequest:PagingContextEntry,IQueryGroup).
            // PagingContextEntry matches NextRowKey that is set in BeforeFill  
            pSalesReprequest:PagingContextEntry = oContextQuery:Entries[1]. // salesrep is first
            super:PreparePaging(pSalesReprequest, pQueryBuilder).
            oMonthPredicate = cast(oContextQuery:Entries[2],IQueryPredicate). // month is second 
            FirstPageMonth = integer(oMonthPredicate:StringValue).
        end.
        else
            super:PreparePaging(pRequest, pQueryBuilder).
          
    end method.
    
    method public void BeforeFill( input dataset-handle phDataset ):
        define variable iSeqNo      as integer   no-undo.
        define variable iTran       as integer   no-undo.
        define variable cQuery      as character no-undo.
        define variable iGroup      as integer   no-undo.
        define variable iMonth      as integer   no-undo.
        define variable iBatch      as int64     no-undo.
        define variable iStartMonth as integer no-undo.
        
        QueryHandle:Query-open().
        
        // set in PreparePaging override
        if FirstPageMonth > 0 then do:
            iStartMonth = FirstPageMonth.
            // the query is on salesrep sp start on salesrep restart rowid 
            QueryHandle:reposition-to-rowid (RestartIds[1]).
            QueryHandle:get-next().
        end.
        else do:
            iStartMonth = 1.
            QueryHandle:get-first().
        end.    
        
        iBatch = GetRequest:NumRecords.
        salesreploop: 
        do while avail salesrep:
            do iMonth = iStartMonth to extent(SalesRep.MonthQuota):
                iSeqNo = iSeqNo + 1.
                // add next batch key and leave if next month reaches batch size (0 = all)
                if iBatch > 0 and iSeqNo >= IBatch + 1 then do:
                    NextRowKey = substitute("Salesrep eq '&1' and Month eq &2",Salesrep.salesrep,IMonth).
                    leave salesreploop.      
                end. 
                create ttSalesRepQuota.
                assign 
                    ttSalesRepQuota.salesrep = SalesRep.salesrep
                    ttSalesRepQuota.month    = IMonth
                    ttSalesRepQuota.quota    = SalesRep.MonthQuota[iMonth]
                    ttSalesRepQuota.zz_seq   = iSeqNo
                    .
            end.    
            QueryHandle:get-next().
            iStartMonth = 1. // set to 1 for remaining salesrpes
        end.
         
        if Count then 
            TotalCount = iSeqNo.
            
        return no-apply. // prevent auto fill that still happens     
    
    end method.
    
     
end class.
