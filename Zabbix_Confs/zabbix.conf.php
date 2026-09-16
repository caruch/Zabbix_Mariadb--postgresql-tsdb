<?php
// Zabbix GUI configuration file.

$DB['TYPE']                     = 'POSTGRESQL';
$DB['SERVER']                   = 'HOST';
$DB['PORT']                     = '5285';
$DB['DATABASE']                 = 'zabbix';
$DB['USER']                     = 'USER';
$DB['PASSWORD']                 = 'PASS';

// Schema name. Used for PostgreSQL.
$DB['SCHEMA']                   = '';

// Used for TLS connection.
$DB['ENCRYPTION']               = true;
$DB['KEY_FILE']                 = '';
$DB['CERT_FILE']                = '';
$DB['CA_FILE']                  = '';
$DB['VERIFY_HOST']              = false;
$DB['CIPHER_LIST']              = '';

// Vault configuration. Used if database credentials are stored in Vault secrets manager.
$DB['VAULT']                    = '';
$DB['VAULT_URL']                = '';
$DB['VAULT_PREFIX']             = '';
$DB['VAULT_DB_PATH']            = '';
$DB['VAULT_TOKEN']              = '';
$DB['VAULT_CERT_FILE']          = '';
$DB['VAULT_KEY_FILE']           = '';
// Uncomment to bypass local caching of credentials.
// $DB['VAULT_CACHE']           = true;

// Uncomment and set to desired values to override Zabbix hostname/IP and port.
$ZBX_SERVER                     = '(Host)';
$ZBX_SERVER_PORT                = '10051';

$ZBX_SERVER_NAME                = '(Host)';

$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;

// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//$HISTORY['url'] = [
//      'uint' => 'http://localhost:9200',
//      'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//$HISTORY['types'] = ['uint', 'text'];

// Used for SAML authentication.
// Uncomment to override the default paths to SP private key, SP and IdP X.509 certificates, and to set extra settings.
//$SSO['SP_KEY']                        = 'conf/certs/sp.key';
//$SSO['SP_CERT']                       = 'conf/certs/sp.crt';
//$SSO['IDP_CERT']              = 'conf/certs/idp.crt';
//$SSO['SETTINGS']              = [];

// If set to false, support for HTTP authentication will be disabled.
// $ALLOW_HTTP_AUTH = true;

$ZBX_SERVER_TLS['ACTIVE'] = '1';
$ZBX_SERVER_TLS['CA_FILE'] = '/etc/httpd/conf.d/certs/CA_intermedia.cer';
$ZBX_SERVER_TLS['KEY_FILE'] = '/etc/httpd/conf.d/certs/wilcard_interno.key';
$ZBX_SERVER_TLS['CERT_FILE'] = '/etc/httpd/conf.d/certs/wildcard_interno_p.cer';
$ZBX_SERVER_TLS['CERTIFICATE_ISSUER']  = '';
$ZBX_SERVER_TLS['CERTIFICATE_SUBJECT'] = '';
