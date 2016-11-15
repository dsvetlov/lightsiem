#!/bin/bash
set -e
./clean.sh
./gen_root_ca.sh capass capass
./gen_node_cert.sh $HOSTNAME changeit capass #&& ./gen_node_cert.sh 1 changeit capass &&  ./gen_node_cert.sh 2 changeit capass
./gen_client_node_cert.sh spock changeit capass
./gen_client_node_cert.sh kirk changeit capass
