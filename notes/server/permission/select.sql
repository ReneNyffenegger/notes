select
   suser_name(srp.grantee_principal_id) grantee,
   srp.permission_name,
-- srp.class,
   srp.class_desc,
   suser_name(srp.grantor_principal_id) grantor,
-- srp.type,
-- srp.state,
   srp.state_desc,
   srp.major_id,
   srp.minor_id
from
   sys.server_permissions srp
order by
   grantee;
