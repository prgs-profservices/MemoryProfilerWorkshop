/*------------------------------------------------------------------------
    File        : TestUpdateSupplier
    Purpose     : Unit test for update of supplier data
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
using Pmfo.Core.Error.BadRequestError from propath.
using OpenEdge.Core.Assert from propath.

class TestDeleteSupplierWithOutstandingPO inherits TestBase:

    define protected property Resource as character no-undo init "suppliers" get.

    @Before.
    method public override void Before():
        super:Before().
    end method.

  
    @test.
    method public void DeleteSupplier(  ):
        define variable oBe               as IBusinessEntity no-undo.
        define variable qmap              as IStringStringMap no-undo.
        define variable oResponse         as JsonObject no-undo.
        define variable oMap              as StringStringMap no-undo.
        define variable oJson             as JsonObject no-undo.
        define variable oJsonWithResponse as JsonObject no-undo.

        oBe = GetBE(Resource).
        ShowErrorsInWindow = true.
        oMap = new StringStringMap().

        // load a posted json for this BE
        oJsonWithResponse = LoadJson(substitute("data/delete-supplier-5.json",Resource)).

        oJson = new JsonObject().
        // add the resource array from the post response to the new json
        oJson:Add(Resource,oJsonWithResponse:GetJsonObject("response"):GetJsonArray(Resource)).

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

        catch e1 as BadRequestError :
            Assert:IsTrue(e1:GetMessage(1) matches "*Supplier*cannot be deleted*","Throw message about supplier cannot be deleted").
        end.
        
        catch e2 as AssertionFailedError :
            HandleError(e2).
        end catch.
                
        // show application errors in a window
        catch e3 as Progress.Lang.Error :
            ShowErrorsInWindow = true.
            HandleError(e3).
        end catch.

    end method.

end class.
