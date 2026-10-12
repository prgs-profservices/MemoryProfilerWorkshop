/*------------------------------------------------------------------------
    File        : TestGetSupplier
    Purpose     : Unit test for read of supplier data    
 ----------------------------------------------------------------------*/

block-level on error undo, throw.

using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.AssertionFailedError from propath.
using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.Collections.StringStringMap from propath.
using Pmfo.Core.BusinessLogic.GetDataRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.QuerySortEntry from propath.
using Pmfo.Tools.Test.TestBase from propath.
using Progress.Json.ObjectModel.JsonObject from propath.

class TestGetSupplier inherits TestBase:

    define protected property BatchSize as integer   no-undo get. set.      
    define protected property Resource  as character no-undo init "suppliers" get.       


    @Before.
    method public void setUpBeforeClass(  ):
        define variable iCount as integer no-undo.

        super:Before(). 
        for each Supplier no-lock:
            BatchSize = BatchSize + 1.
            if BatchSize > 20 then leave.
        end.   
        BatchSize = max(0,BatchSize - 1).       
        release Supplier.
    end method.

    @Test.
    // simulate web request from operationhandler  
    method public void GetSupplier():
        define variable oBe               as IBusinessEntity  no-undo.
        define variable omap              as IStringStringMap no-undo. 
        define variable oResponse         as JsonObject       no-undo.
        define variable cPublicNameOrDesc as character        no-undo.   
        define variable oJson             as JsonObject       no-undo.

        oBe = GetBE(Resource).
        cPublicNameOrDesc  = oBe:GetPublicTextField().

        // simulate url query properties from web 
        oMap = new StringStringMap().
        oMap:put("top","1").
        oMap:put("orderBy",string(cPublicNameOrDesc)).

        oResponse = this-object:OperationHandler:ExecuteRead(
                        "GET",
                        "http://10.0.0.198:8080/minster/web/api", 
                        Resource,
                        oMap, 
                        oBe).

        oResponse:WriteFile(substitute("temp/get-&1.json",Resource),true).

        if BatchSize > 0 then 
            Assert:IsTrue(oResponse:Has(substitute("&1@nextBatchLink",Resource)),"Response has next batch Link"). 

        if cPublicNameOrDesc > "" then 
            Assert:IsTrue(IsJsonArraySortedByProperty(oResponse:GetJsonObject("response"):GetJsonArray(Resource),cPublicNameOrDesc,true),substitute("Sorted on &1",cPublicNameOrDesc)).


        return.
        catch e1 as AssertionFailedError :
            HandleError(e1).    
        end catch. 

        // show application errors in a window
        catch e2 as Progress.Lang.Error :
            ShowErrorsInWindow = true. 
            HandleError(e2).    
        end catch. 

    end method.


   // @Test.
    method public void GetSupplierUseBE():
        define variable oBe                as IBusinessEntity      no-undo.
        define variable hDataset           as handle               no-undo.
        define variable oRequest           as IGetDataRequest      no-undo.
        define variable oResponse          as IGetDataResponse     no-undo.
        define variable oTableRequest      as IGetDataTableRequest no-undo.
        define variable i                  as integer              no-undo.
        define variable cNameOrDescription as character            no-undo.   
        define variable cPublicNameOrDesc  as character            no-undo.   
        define variable oJson              as JsonObject           no-undo.

        oBe = GetBE(Resource).

       /* by-reference - The SupplierBE is currenty restricted to only use the internal 
          dataset for GetData since it uses another static dataset to send data to server
          This is default when renning from WEB */        
        oBe:getDataset(output dataset-handle hDataset by-reference).
        oRequest = new GetDataRequest().
        cNameOrDescription = oBe:GetTextField().
        cPublicNameOrDesc  = oBe:GetPublicTextField().
        do i = 1 to hDataset:num-buffers:
            oTableRequest =  new GetDataTableRequest(hDataset:get-buffer-handle(i):table-handle).
            if i = 1 then do:
                 // sort on name/description 
                 if cNameOrDescription > "" then 
                     oTableRequest:SetQuerySort(new QuerySortEntry(cNameOrDescription)).
                 // set batch size 
                 oTableRequest:NumRecords = BatchSize.
            end.    
            oRequest:AddTableRequest(oTableRequest).  
        end.         

        oResponse = oBe:GetData(oRequest,output dataset-handle hdataset by-reference).
        oJson = new JsonObject().
        // write without dataset serialize-name  
        hDataset:write-json("JsonObject",oJson,yes,?,no,yes).

        oJson:WriteFile(substitute("temp/get-be-&1.json",Resource),yes). 

        if cPublicNameOrDesc > "" then 
            Assert:IsTrue(IsJsonArraySortedByProperty(oJson:GetJsonArray(Resource),cPublicNameOrDesc,true),substitute("Sorted on &1",cNameOrDescription)).

        do i = 1 to extent(oResponse:TableResponses):
            if i = 1 then 
                Assert:NotEmpty(oResponse:TableResponses[i]:NextPagingContext,"NextPagingContext").
        end.         

        return.
        catch e1 as AssertionFailedError :
            HandleError(e1).    
        end catch. 

        // show application errors in a window
        catch e2 as Progress.Lang.Error :
            ShowErrorsInWindow = true. 
            HandleError(e2).    
        end catch. 

        finally:
            // ensure the dataset is not shown if memory profiler is active 
            if valid-object(hDataset) then 
                delete object hDataset.        
        end finally. 
    end method.    

end class.
