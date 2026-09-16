mysqldump -u root --single-transaction --quick \
  --ignore-table=zabbix_v01.history \
  --ignore-table=zabbix_v01.history_uint \
  --ignore-table=zabbix_v01.history_str \
  --ignore-table=zabbix_v01.history_text \
  --ignore-table=zabbix_v01.history_log \
  --ignore-table=zabbix_v01.history_bin \
  --ignore-table=zabbix_v01.trends \
  --ignore-table=zabbix_v01.trends_uint \
  --ignore-table=zabbix_v01.auditlog \
  zabbix_v01 > zabbix_config_sin_historial.sql
