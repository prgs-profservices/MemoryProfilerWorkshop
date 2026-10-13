/*
Use to import from .d and support both update and create
Syntax: 
import of table with one field in unique index 
{import_table.i customer custnum} 
import of table with two fields in unique index 
{import_table.i orderLine ordernum linenum} 

supports up to 6 fieldsas parameters

Supress message
&scop silent
{import_table.i customer custnum} 


*/ 

/* ***************************  Declarations  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */
&if "{&path}" = "" &then 
   &scop path dump
&endif 
       
&scop tablename {1}

&if "{3}" <> "" &then 
&scop dumpname {3}
&else
&scop dumpname {&tablename}
&endif 

&scop key {2} 
&scop key2 {4} 
&scop key3 {5} 
&scop key4 {6} 
&scop key5 {7} 
&scop key6 {8} 


/* ***************************  Main Block  *************************** */ 
  
input from {&path}\{&dumpname}.d.

define temp-table tt{&tablename} like {&tablename}.
define variable iCount as int64 no-undo.
define variable iCreate as int64 no-undo.
pause 0 before-hide.
create tt{&tablename}.
loop:
repeat:
     import tt{&tablename}.
     do transaction:
         find {&tablename} exclusive-lock where {&tablename}.{&key} = tt{&tablename}.{&key}
         &if "{&key2}" <> "" &then
                                           and {&tablename}.{&key2} = tt{&tablename}.{&key2}
         &endif
         &if "{&key3}" <> "" &then
                                           and {&tablename}.{&key3} = tt{&tablename}.{&key3}
         &endif
         &if "{&key4}" <> "" &then
                                           and {&tablename}.{&key4} = tt{&tablename}.{&key4}
         &endif
         &if "{&key5}" <> "" &then
                                           and {&tablename}.{&key5} = tt{&tablename}.{&key5}
         &endif
         &if "{&key6}" <> "" &then
                                           and {&tablename}.{&key6} = tt{&tablename}.{&key6}
         &endif
         no-error.
         iCount = iCount  + 1.
         {&check}
         if not avail {&tablename} then
         do:
            create {&tablename}.
            iCreate = iCreate + 1.
         end.

         buffer-copy tt{&tablename} to {&tablename}.
     end.

end.

&if defined(silent) = 0 &then 

message "Imported {&tablename}" skip
        "Created:" iCreate  skip
        "Updated:" iCount  
 view-as alert-box information.

&endif 
