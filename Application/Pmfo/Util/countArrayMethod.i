
/*------------------------------------------------------------------------
    File        : countArrayMethod.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : 05/10/2025 
    Notes       :
  ----------------------------------------------------------------------*/
    method public static integer Count (pValue as {1}, pArray as {1} extent):
        var integer i, iCount.
        
        do i = 1 to extent(pArray):
            if pArray[i] = pValue then 
                iCount = iCount + 1. 
        end.   
        return iCount.        
    end method.
    
     