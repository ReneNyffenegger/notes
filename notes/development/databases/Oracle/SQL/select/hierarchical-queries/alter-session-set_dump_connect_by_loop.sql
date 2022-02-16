



alter session set "_dump_connect_by_loop_data" = true;




alter session set "_dump_connect_by_loop_data" = true;

select
   trc.payload,
   trc.timestamp
from
   v$diag_info inf   join
   v$diag_trace_file_contents  trc on regexp_replace(inf.value, '.*[\\/]', '') = trc.trace_filename
where
   inf.name = 'Default Trace File'
order by
   trc.line_number
;
