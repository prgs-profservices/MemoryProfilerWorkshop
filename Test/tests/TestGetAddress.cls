/*------------------------------------------------------------------------
    File        : TestGetBenefits
    Purpose     : Unit test for read of benefits data    
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
using Pmfo.Util.Array from propath.
using Ccs.BusinessLogic.IQuerySortEntry from propath.
using Ccs.BusinessLogic.SortOrderEnum from propath.

class TestGetAddress inherits TestBase:

    
    define protected property Resource  as character no-undo init "addresses" get.       


    @Before.
    method public void setUpBeforeClass(  ):
        super:Before(). 
    end method.

    @Test.

    // simulate web request from operationhandler  
    method public void GetAddresses():
        define variable oBe               as IBusinessEntity  no-undo.
        define variable omap              as IStringStringMap no-undo. 
        define variable oResponse         as JsonObject       no-undo.
        define variable oJson             as JsonObject       no-undo.

        oBe = GetBE(Resource).
      
        // simulate url query properties from web 
        oMap = new StringStringMap().
        oMap:put("top","20").
        oMap:put("orderBy","address desc, adresss2 desc").

        oResponse = this-object:OperationHandler:ExecuteRead(
                        "GET",
                        "http://10.0.0.198:8080/minster/web/api", 
                        Resource,
                        oMap, 
                        oBe).

        oResponse:WriteFile(substitute("temp/get-&1.json",Resource),true).

        Assert:IsTrue(oResponse:Has(substitute("&1@nextBatchLink",Resource)),"Response has next batch Link"). 

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


    @Test.
    method public void GetAddressesUseBE():
        define variable oBe                as IBusinessEntity      no-undo.
        define variable hDataset           as handle               no-undo.
        define variable oRequest           as IGetDataRequest      no-undo.
        define variable oResponse          as IGetDataResponse     no-undo.
        define variable oTableRequest      as IGetDataTableRequest no-undo.
        define variable i                  as integer              no-undo.
        define variable oJson              as JsonObject           no-undo.
        define variable oSort              as IQuerySortEntry    extent no-undo. 
        oBe = GetBE(Resource).

        // grab a deep copy to test GetData with external dataset - not depending on the static definition in the class
        oBe:getDataset(output dataset-handle hDataset).
        oRequest = new GetDataRequest().
        do i = 1 to hDataset:num-buffers:
            oTableRequest =  new GetDataTableRequest(hDataset:get-buffer-handle(i):table-handle).
            if i = 1 then do:
                 extent(oSort) = 2.
                 oSort[1] =  new QuerySortEntry("address",SortOrderEnum:Descending).
                 oSort[2] =  new QuerySortEntry("address2",SortOrderEnum:Descending).
                 oTableRequest:SetQuerySort(oSort).
                 // set batch size 
                 oTableRequest:NumRecords = 20.
            end.    
            oRequest:AddTableRequest(oTableRequest).  
        end.         

        oResponse = oBe:GetData(oRequest,output dataset-handle hdataset by-reference).
        oJson = new JsonObject().
        // write without dataset serialize-name  
        hDataset:write-json("JsonObject",oJson,yes,?,no,yes).

        oJson:WriteFile(substitute("temp/get-be-&1.json",Resource),true). 
        
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
