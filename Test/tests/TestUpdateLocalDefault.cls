/*------------------------------------------------------------------------
    File        : TestUpdateLocalDefault
    Purpose     : Unit test for update of localDefault data
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using OpenEdge.Core.AssertionFailedError from propath.
using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.Collections.StringStringMap from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.UpdateDataRequest from propath.
using Pmfo.Core.Service.OperationHandler from propath.
using Pmfo.Tools.Test.TestBase from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.JsonUtil from propath.
using Progress.Json.ObjectModel.JsonObject from propath.

class TestUpdateLocalDefault inherits TestBase:

    define protected property Resource as character no-undo init "localDefaults" get.
 
    @Before.
    method public override void Before():
        super:Before().
    end method.

    @Test.
    method public void PostLocalDefault(  ):
        define variable oBe           as IBusinessEntity no-undo.
        define variable qmap          as IStringStringMap no-undo.
        define variable oMap          as StringStringMap no-undo.
        define variable oJson         as JsonObject no-undo.
        define variable oResponse     as JsonObject no-undo.

        oBe   = GetBE(Resource).
        oMap  = new StringStringMap().

        // load the predefined test data
        oJson = LoadJson(substitute("data/post-&1.json",Resource)).

        oResponse = OperationHandler:ExecuteUpdate(
                               "POST",
                               oJson,
                               "http://10.0.0.198:8080/minster/web/api",
                               Resource,
                               oMap,
                               oBe).

        oResponse:WriteFile(substitute("temp/posted-&1.json",Resource), true).

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

    @test.
    method public void DeleteLocalDefault(  ):
        define variable oBe               as IBusinessEntity no-undo.
        define variable qmap              as IStringStringMap no-undo.
        define variable oResponse         as JsonObject no-undo.
        define variable oMap              as StringStringMap no-undo.
        define variable oJson             as JsonObject no-undo.
        define variable oJsonPosted       as JsonObject no-undo.

        oBe = GetBE(Resource).
        ShowErrorsInWindow = true.
        oMap = new StringStringMap().

        // load the last posted json for this BE
        oJsonPosted = LoadJson(substitute("temp/posted-&1.json",Resource)).

        oJson = new JsonObject().
        // add the resource array from the post response to the new json
        oJson:Add(Resource,oJsonPosted:GetJsonObject("response"):GetJsonArray(Resource)).

        oResponse = OperationHandler:ExecuteUpdate(
                        "DELETE",
                        oJson,
                        "http://10.0.0.198:8080/minster/web/api",
                        Resource,
                        oMap,
                        oBe).

        // default for delete is no json (HTTP 204), but theee will be a if there are warnings
        if valid-object(oResponse) then
            oResponse:WriteFile(substitute("temp/deleted-&1.json",Resource), true).

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
    method public void CreateLocalDefaultUsingBE(  ):
        define variable oBe                as IBusinessEntity no-undo.
        define variable hDataset           as handle no-undo.
        define variable oJson              as JsonObject no-undo.
        define variable oUpdateRequest     as IUpdateDataRequest  no-undo.
        define variable cMainRequestBuffer as character no-undo.

        oBe = GetBE(Resource).

        // grab a deep copy to test UpdateData without depending on the static definition in the class
        oBe:getDataset(output dataset-handle hDataset).
        cMainRequestBuffer = hDataset:get-buffer-handle(1):name.

        // load the predefined test data
        oJson = LoadJson(substitute("data/post-&1.json",Resource)).
        // wrap the json with a dataset node for read-json (still needed in version 12?)
        oJson = JsonUtil:WrapRequestForDataset(ojson, hDataset,cMainRequestBuffer).

        // set tracking on all buffer so the records will be marked as row-created when using read-json
        DatasetUtil:SetTrackingChanges(hdataset,true).
        hDataset:read-json ("JsonObject",oJson).

        oUpdateRequest = new UpdateDataRequest(cMainRequestBuffer).
        oBe:UpdateData(input-output dataset-handle hdataset by-reference, oUpdateRequest).
        // log the json - will be used for delete
        hDataset:write-json ("file",substitute("temp/posted-be-&1.json",Resource),yes).

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

    @Test.
    method public void DeleteLocalDefaultUsingBE(  ):
        define variable oBe                as IBusinessEntity no-undo.
        define variable hDataset           as handle no-undo.
        define variable oJson              as JsonObject no-undo.
        define variable oUpdateRequest     as IUpdateDataRequest  no-undo.
        define variable cMainRequestBuffer as character no-undo.

        oBe = GetBE(Resource).
        // grab a deep copy to test UpdateData without depending on the static definition in the class
        oBe:getDataset(output dataset-handle hDataset).
        cMainRequestBuffer = hDataset:get-buffer-handle(1):name.

        // load the last posted json for this BE
        oJson = LoadJson(substitute("temp/posted-be-&1.json",Resource)).
        hDataset:read-json ("JsonObject",ojson).
        // mark all rows as row-deleted (delete with tracking-changes)
        DeleteDataAndTrack(hDataset).

        oUpdateRequest = new UpdateDataRequest(cMainRequestBuffer).
        oBe:UpdateData(input-output dataset-handle hdataset by-reference, oUpdateRequest).

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
