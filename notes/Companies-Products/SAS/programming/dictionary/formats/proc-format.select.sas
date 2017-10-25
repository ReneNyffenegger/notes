proc format;
  picture
     ddmmyyyy_hh24miss 
    (default=19)                   /* <-- default width of format */
     other='%0d.%0m.%Y %0H:%0M:%0S'
    (datatype=datetime);
  
run;

proc sql;
  select *
  from
    dictionary.formats
  where
    libname = 'WORK' and
    objname = 'DDMMYYYY_HH24MISS';
quit;
