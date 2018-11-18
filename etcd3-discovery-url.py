#!/usr/bin/env python

# ## #################################################################### ## #
# ## devops4me.etcd3-cluster/etcd3-discovery-url.py                       ## #
# ## #################################################################### ## #
#
# Here are the important items to note before running or
# when trouble-shooting this script.
#
#  [1] - the [requests] package must be installed before running this
#        script. For CI this is done inside the Dockerfile.
#          $ pip install requests
#
#  [2] - it pays to give this script execute permissions
#          $ chmod u+x etcd3-discovery-url.py
#
#  [3] - try out this script from its directory with these commands
#          $ python etcd3-discovery-url.py 3
#          $ ./etcd3-discovery-url.py 3
#
#  [4] - an invalid syntax error "json.dumps" occurs if python3 used
#
#  [5] - it expects number of nodes in the cluster as the first parameter
#
#  [6] - output is a JSON formatted string with key "etcd_discovery_url"
#
#  [7] - Logs are printed to file [etcd3-discovery-url.log] in the same folder.
#
#  [8] - Example Command and Output
#
#          $ ./etcd3-discovery-url.py 3
#          {"etcd_discovery_url": "https://discovery.etcd.io/a660b68aa151605f0ed32807b4be165f"}
#
# ## #################################################################### ## #

# Example Output
# {"ip_addresses": "10.42.1.230,10.42.1.39,10.42.1.139,10.42.0.108"}

import requests, json, sys, logging

logging.basicConfig( filename = 'etcd3-discovery-url.log', level = logging.DEBUG, format='%(asctime)s %(message)s', datefmt='%Y%m%d %I:%M:%S %p' )

logging.info( '[etcd3-discovery-url.py] invoking script to grab an etcd discovery url.' )
logging.info( 'The stated node count in the etcd cluster is [%s]' % ( sys.argv[1] ) )

payload = { 'size': sys.argv[1] }
response = requests.get( 'https://discovery.etcd.io/new', params=payload )

logging.info( 'The etcd discovery url retrieved is [%s]' % ( response.text ) )

OUTPUT_VARIABLE_NAME = "etcd_discovery_url"
print json.dumps( { OUTPUT_VARIABLE_NAME : response.text } )
