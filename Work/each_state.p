 

block-level on error undo, throw.

define variable i as integer no-undo. 
for each state no-lock :
    i = i + 1.
    display State.
end.    

message i
view-as alert-box.