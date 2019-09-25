#!/bin/bash
docker-machine inspect $DOCKER_MACHINE_NAME | python -c "import json,sys;obj=json.load(sys.stdin);print obj['Driver']['SSHUser'];"
