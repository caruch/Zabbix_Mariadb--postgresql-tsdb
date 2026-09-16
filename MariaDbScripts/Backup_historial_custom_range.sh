mysqldump -u root --single-transaction --quick \
  --where="clock BETWEEN UNIX_TIMESTAMP('2026-09-15 10:00:00') AND UNIX_TIMESTAMP('2026-09-15 12:00:00')" \
  zabbix_v01 \
  history history_uint history_str history_text history_log history_bin \
  trends trends_uint \
  auditlog \
  > zabbix_historial_custom.sql
