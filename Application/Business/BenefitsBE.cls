/*------------------------------------------------------------------------------
 File        : Business.BenefitsBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/13/2026 07:21:31.639-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.BenefitsBE inherits BusinessEntity:

    {schema/benefits.i}

    define dataset dsBenefits for ttBenefits.

    constructor BenefitsBE():
        super(dataset dsBenefits:handle).
    end constructor.

end class.
