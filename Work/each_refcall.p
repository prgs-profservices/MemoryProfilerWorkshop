 

block-level on error undo, throw.

current-window:width = 400.
 
for each refcall no-lock by parent with frame a width 330 stream-io:
    display RefCall.Parent RefCall.CallNum.
    display RefCall.Txt view-as text format "x(100)".
    display RefCall.                                        
end.    
