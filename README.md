# Zabbix_Mariadb--postgresql-tsdb

Repositorio con todo lo necesario para migrar la base de datos de **Zabbix** desde **MariaDB** hacia **PostgreSQL + TimescaleDB**, junto con la configuración de conexión TLS entre Zabbix Server/Frontend y la nueva base.

## Contenido

### `MariaDbScripts/`
Scripts para extraer los datos desde el origen (MariaDB):
- `Backup_conf.sh`: hace un `mysqldump` de la base excluyendo las tablas de historial/tendencias/auditoría, para obtener solo la **configuración** de Zabbix.
- `Backup_historial_custom_range.sh`: hace un `mysqldump` únicamente de las tablas de historial, tendencias y auditlog, filtrando por un **rango de fechas** personalizable (`clock BETWEEN ...`).

### `PostgreSQLScripts/`
Scripts para cargar los datos en destino (PostgreSQL) usando `pgloader`:
- `Migracion_conf.load`: migra la configuración de Zabbix (excluye tablas de historial/tendencias/auditlog).
- `Migracion_data.load`: migra únicamente el historial, las tendencias y el auditlog.
- `gestion_PostgreSQL.sh`: script interactivo para administrar la base PostgreSQL de destino (limpiar la base, restaurar un dump, o tomar un backup con `pg_dump`).

### `Zabbix_Confs/`
Configuración base para que **Zabbix Server** y **Zabbix Frontend** se conecten a PostgreSQL con TLS:
- `zabbix_server.conf`: configuración del servidor (conexión a la DB y certificados TLS).
- `zabbix.conf.php`: configuración del frontend (conexión a la DB y certificados TLS).

## Cosas importantes a saber

- **Instalar `pgloader`**: es la herramienta usada para migrar de MySQL/MariaDB a PostgreSQL. Se puede instalar vía gestor de paquetes del sistema (`apt install pgloader` / `dnf install pgloader`) o compilarlo desde su [repositorio oficial](https://github.com/dimitri/pgloader).
- **Instalar `mysqldump`**: viene incluido en el cliente de MySQL/MariaDB (`mariadb-client` / `mysql-client`), necesario para generar los backups en `MariaDbScripts/`.
- **Versiones de Zabbix**: la versión de Zabbix debe ser **la misma** en origen y destino durante toda la migración, para evitar incompatibilidades de esquema.
- **Variables sensibles**: los archivos de este repo tienen los valores de **host, puerto, usuario y contraseña** reemplazados por placeholders (por motivos de seguridad). Antes de usarlos hay que completarlos con los datos reales del entorno correspondiente.
