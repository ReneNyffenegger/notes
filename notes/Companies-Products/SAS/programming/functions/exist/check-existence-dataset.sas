%macro doesTableExist(tab);

  %if %sysfunc(exist(&tab))
      %then %put Table &tab does indeed exist;
      %else %put Table &tab does not exist;

%mend;

%doesTableExist(tq84_tab);

data tq84_tab;
  x = 'foo';
  y = 'bar';
  z = 'baz';
run;

%doesTableExist(tq84_tab);

proc delete
     data = tq84_tab;
run;

%doesTableExist(tq84_tab);
