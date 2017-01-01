#!/bin/bash
set -e
/usr/share/elasticsearch/plugins/search-guard-5/tools/sgadmin.sh \
   -cd /usr/share/elasticsearch/plugins/search-guard-5/sgconfig/ \
   -ks /etc/elasticsearch/sg/admin-keystore.jks \
   -ts /etc/elasticsearch/sg/truststore.jks \
   -kspass changeit \
   -tspass capass \
   -nhnv
