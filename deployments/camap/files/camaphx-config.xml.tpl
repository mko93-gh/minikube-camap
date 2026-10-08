<config
  lang="fr"
  langs="fr"
  langnames="Français"

  host="${CAMAP_HOSTNAME}"
  name="${CAMAP_INSTANCE_NAME}"
  webmaster_email="${WEBMASTER_EMAIL}"

  database="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}/${MYSQL_DATABASE}"
  sqllog="0"

  debug="${CAMAP_DEBUG}"
  cache="${CAMAP_CACHE}"
  maintain="0"
  cachetpl="0"
  key="${CAMAP_KEY}"

  camap_api="${CAMAP_API_URL}"
  camap_bridge_api="${CAMAP_BRIDGE_API_INTERNAL}"

  mapbox_server_token="${MAPBOX_KEY}"
/>