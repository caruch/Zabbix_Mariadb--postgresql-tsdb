#!/usr/bin/env bash
#
# gestion_postgresql.sh
#
# Script de gestión de base de datos PostgreSQL para RHEL9.
# Permite:
#   1) Limpiar la base de datos (drop/recreate schema public)
#   2) Restaurar un dump sobre la base
#   3) Tomar un backup (pg_dump) con timestamp en el nombre
#
# Requiere: psql, pg_dump, pg_restore (paquete postgresqlXX o postgresqlXX-contrib
# / postgresql-client según versión) instalados y en el PATH.
#
set -uo pipefail

# ============================================================
# CONFIGURACIÓN DE CONEXIÓN
# ============================================================
PG_HOST="IP_SERVER"
PG_PORT="PORT_SERVER"
PG_USER="USER"
PG_SSLMODE="require"

DUMP_FOLDER="./dumps"
mkdir -p "$DUMP_FOLDER"

# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

leer_password() {
    read -r -s -p "Ingrese password: " PGPASSWORD
    echo
    export PGPASSWORD
}

limpiar_password() {
    unset PGPASSWORD
}

test_conexion() {
    local db="$1"
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db" \
         "sslmode=${PG_SSLMODE}" -c "SELECT 1;" >/dev/null 2>&1
}

confirmar() {
    local mensaje="$1"
    local respuesta
    read -r -p "$mensaje (escriba SI para confirmar): " respuesta
    [[ "$respuesta" == "SI" ]]
}

# Consulta al servidor la lista de bases de datos disponibles (excluye plantillas)
# y las imprime en un array por referencia ($1 = nombre del array destino).
obtener_bases() {
    local -n _destino="$1"
    local salida
    local conectado=0
    local db_admin

    for db_admin in postgres template1; do
        salida="$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db_admin" \
                        "sslmode=${PG_SSLMODE}" -X -A -t -q \
                        -c "SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname;" 2>/dev/null)"
        if [[ $? -eq 0 ]]; then
            conectado=1
            break
        fi
    done

    if [[ $conectado -eq 0 ]]; then
        return 1
    fi

    mapfile -t _destino <<< "$salida"
    return 0
}

# Muestra un menú numerado a partir de un array por referencia ($1 = nombre del array)
# y devuelve en la variable global SELECCION el elemento elegido.
elegir_de_lista() {
    local -n _items="$1"
    local titulo="$2"
    local i

    echo
    echo "--- ${titulo} ---"
    for i in "${!_items[@]}"; do
        printf "%2d) %s\n" "$((i + 1))" "${_items[$i]}"
    done
    echo " 0) Ingresar manualmente"
    echo

    local eleccion
    read -r -p "Seleccione una opción: " eleccion

    if [[ "$eleccion" == "0" ]]; then
        read -r -p "Ingrese el valor manualmente: " SELECCION
        return
    fi

    if ! [[ "$eleccion" =~ ^[0-9]+$ ]] || (( eleccion < 1 || eleccion > ${#_items[@]} )); then
        echo "Opción inválida." >&2
        return 1
    fi

    SELECCION="${_items[$((eleccion - 1))]}"
}

# Pide nombre_base: intenta listar las bases del servidor y ofrecer un menú;
# si no puede listarlas (permisos, etc.), pide el nombre manualmente.
pedir_nombre_base() {
    local bases=()
    if obtener_bases bases && [[ ${#bases[@]} -gt 0 ]]; then
        if elegir_de_lista bases "Bases de datos disponibles"; then
            nombre_base="$SELECCION"
        else
            return 1
        fi
    else
        read -r -p "Ingrese nombre_base: " nombre_base
    fi

    if [[ -z "$nombre_base" ]]; then
        echo "El nombre de la base no puede estar vacío." >&2
        return 1
    fi
}

# Pide nombre_dump: lista los archivos de $DUMP_FOLDER y ofrece un menú;
# si la carpeta está vacía, pide el nombre/ruta manualmente.
pedir_nombre_dump() {
    local archivos=()
    local f

    if [[ -d "$DUMP_FOLDER" ]]; then
        while IFS= read -r -d '' f; do
            archivos+=("$(basename "$f")")
        done < <(find "$DUMP_FOLDER" -maxdepth 1 -type f \
                       \( -name "*.sql" -o -name "*.dump" -o -name "*.backup" -o -name "*.tar" \) \
                       -print0 | sort -z)
    fi

    if [[ ${#archivos[@]} -gt 0 ]]; then
        if elegir_de_lista archivos "Dumps disponibles en ${DUMP_FOLDER}"; then
            nombre_dump="$SELECCION"
        else
            return 1
        fi
    else
        echo "No se encontraron dumps en ${DUMP_FOLDER}."
        read -r -p "Ingrese nombre_dump (ruta o archivo): " nombre_dump
    fi

    if [[ -z "$nombre_dump" ]]; then
        echo "El nombre del dump no puede estar vacío." >&2
        return 1
    fi
}

# ============================================================
# OPCIÓN 1 - LIMPIAR BASE DE DATOS
# ============================================================
limpiar_base() {
    local db="$1"

    echo
    echo "--- LIMPIAR BASE: ${db} ---"

    if ! confirmar "Esto borrará TODO el contenido de '${db}'."; then
        echo "Operación cancelada."
        return
    fi

    if ! test_conexion "$db"; then
        echo "No se pudo conectar a la base '${db}'. Verifique el nombre y la contraseña." >&2
        return 1
    fi

    echo "Ejecutando limpieza (DROP/CREATE SCHEMA public)..."
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db" \
         "sslmode=${PG_SSLMODE}" -v ON_ERROR_STOP=1 <<-SQL
        DROP SCHEMA public CASCADE;
        CREATE SCHEMA public;
        GRANT ALL ON SCHEMA public TO public;
SQL

    if [[ $? -eq 0 ]]; then
        echo "Base '${db}' limpiada correctamente."
    else
        echo "Ocurrió un error al limpiar la base." >&2
        return 1
    fi
}

# ============================================================
# OPCIÓN 2 - RESTAURAR DUMP
# ============================================================
restaurar_dump() {
    local db="$1"
    local dump_name="$2"
    local dump_path="$dump_name"

    echo
    echo "--- RESTAURAR DUMP: ${dump_name} -> ${db} ---"

    if [[ ! -f "$dump_path" ]]; then
        dump_path="${DUMP_FOLDER}/${dump_name}"
    fi
    if [[ ! -f "$dump_path" ]]; then
        echo "No se encontró el archivo de dump: ${dump_name}" >&2
        echo "Se buscó en la ruta indicada y en '${DUMP_FOLDER}'." >&2
        return 1
    fi

    if ! test_conexion "$db"; then
        echo "No se pudo conectar a la base '${db}'. Verifique el nombre y la contraseña." >&2
        return 1
    fi

    if ! confirmar "Se restaurará '${dump_path}' sobre la base '${db}'."; then
        echo "Operación cancelada."
        return
    fi

    echo "Restaurando dump, esto puede tardar unos minutos..."

    case "$dump_path" in
        *.sql)
            # Dump en formato plano (texto SQL)
            psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db" \
                 "sslmode=${PG_SSLMODE}" -v ON_ERROR_STOP=1 -f "$dump_path"
            ;;
        *)
            # Dump en formato custom/tar/directory (pg_dump -Fc, -Ft, -Fd)
            pg_restore -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db" \
                       --no-owner --no-privileges --clean --if-exists \
                       -v "$dump_path"
            ;;
    esac

    if [[ $? -eq 0 ]]; then
        echo "Dump restaurado correctamente en '${db}'."
    else
        echo "La restauración finalizó con errores. Revise el detalle arriba." >&2
        return 1
    fi
}

# ============================================================
# OPCIÓN 3 - BACKUP DE LA BASE
# ============================================================
backup_base() {
    local db="$1"

    echo
    echo "--- BACKUP DE LA BASE: ${db} ---"

    if ! test_conexion "$db"; then
        echo "No se pudo conectar a la base '${db}'. Verifique el nombre y la contraseña." >&2
        return 1
    fi

    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_name="${db}_${timestamp}.dump"
    local backup_path="${DUMP_FOLDER}/${backup_name}"

    echo "Generando backup en formato custom (pg_dump -Fc): ${backup_path}"

    pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db" \
            "sslmode=${PG_SSLMODE}" -Fc -v -f "$backup_path"

    if [[ $? -eq 0 ]]; then
        echo "Backup generado correctamente: ${backup_path}"
    else
        echo "Ocurrió un error al generar el backup." >&2
        return 1
    fi
}

# ============================================================
# MENÚ PRINCIPAL
# ============================================================
mostrar_menu() {
    echo
    echo "========================================="
    echo "   GESTIÓN DE BASE DE DATOS POSTGRESQL"
    echo "   Servidor: ${PG_HOST}:${PG_PORT} (usuario: ${PG_USER})"
    echo "========================================="
    echo "1) Limpiar base de datos"
    echo "2) Restaurar dump"
    echo "3) Tomar backup de la base"
    echo "0) Salir"
    echo "========================================="
}

# ============================================================
# FLUJO PRINCIPAL
# ============================================================
main() {
    mostrar_menu
    read -r -p $'\nSeleccione una opción: ' opcion

    if [[ "$opcion" == "0" ]]; then
        echo "Saliendo..."
        exit 0
    fi

    if [[ "$opcion" != "1" && "$opcion" != "2" && "$opcion" != "3" ]]; then
        echo "Opción inválida." >&2
        exit 1
    fi

    # La password se pide primero porque hace falta para poder listar
    # las bases de datos existentes en el servidor.
    leer_password
    trap limpiar_password EXIT

    local nombre_base
    local nombre_dump

    pedir_nombre_base || exit 1

    case "$opcion" in
        1)
            limpiar_base "$nombre_base"
            ;;
        2)
            pedir_nombre_dump || exit 1
            restaurar_dump "$nombre_base" "$nombre_dump"
            ;;
        3)
            backup_base "$nombre_base"
            ;;
    esac
}

main "$@"
