#!/bin/bash
if docker-machine inspect $DOCKER_MACHINE_NAME | grep -q 'virtualbox'; then
  echo "True"
else 
  echo "False"	
fi
