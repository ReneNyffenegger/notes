%macro tq84_assertHost(host);

  %if &syshostname ne &host %then %do;
    %put ERROR: Assertion failed, not running on &host but on &syshostname;
    %abort;
  %end;

  %put INFO: OK: Running on &syshostname;

%mend tq84_assertHost;

/* Assert we're running on host with name tq84 */
%tq84_assertHost(tq84);
