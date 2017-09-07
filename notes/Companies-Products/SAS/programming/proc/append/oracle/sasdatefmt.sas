/*     Specify Oracle user, password and server: */
%let ora_user     = tq84;
%let ora_password = secret_garden;
%let ora_server   = ora.test.renenyffenegger.ch;


/* Create a table with a test date */
proc sql;
  connect to oracle (
    user     = &ora_user
    password = &ora_password
    path     = &ora_server
  );
  execute (
    create table tq84_date_test (
      id     number primary key,
      col_1  varchar2(20),
      dt     date not null  check (dt = trunc(dt))
    )
  ) by oracle;
quit;


/* Fill some values into the table: */
libname tq84_ora oracle 
  path               = &ora_server
  user               = &ora_user
  password           = &ora_password
  /*sql_functions      = all*/
;


/* Load data into stage table */
data work.tq84_stage;
  length
    id     8.
    col_1  $20.
    dt     8.;

  informat dt date9.;
  format   dt date9.;

  infile datalines dlm=',' dsd;

  input id
        col_1
        dt
  ;
datalines;
1,Sep,01sep17
2,two,02sep17
3,three,03sep17
11,eleven,11sep17
12,twelve,12sep17
13,thirteen,13sep17
;


/* Transfer data from stage table to Oracle table */
proc append 
     data=work.tq84_stage
     base=tq84_ora.tq84_date_test(
     /* use SASDATEFMT to prevent
           Variable dt has format 'DATETIME20.'n on the
           BASE data set and format 'DATE9.'n on the DATA data set.
     */
        sasdatefmt=(dt='date9.')
     )
;
run;

data work.tq84_tev_selected;
  set   tq84_ora.tq84_date_test;
  where dt eq '02sep17'd;
run;
