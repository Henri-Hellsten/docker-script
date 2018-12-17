#!/bin/bash

#
# Variables
#
source docker-config.sh

#
# Help
#
function help {
  echo "Usage:"
  echo "  docker.sh command [command command ..]"
  echo ""
  echo "Commands:"
  echo "  access            Access docker container"
  echo "  build/rebuild     Build docker container or rebuild from scratch"
  echo "  clean             Clean docker temporary files"
  echo "  start             Start docker container"
}

#
# Access docker container
#
function access {
  sudo docker exec -it $CONTAINER /bin/bash
}

#
# Build docker container
#
function build {
  sudo docker build -t $CONTAINER:latest .
}

#
# Re-build docker container
#
function rebuild {
  sudo docker build --no-cache -t $CONTAINER:latest .
}

#
# Clean docker container
#
function clean {
  # Stop and remove current container if found
  RESP=$(sudo docker ps -qa --no-trunc --filter "name=$CONTAINER")
  if [ ! -z "$RESP" ]; then
    sudo docker stop $RESP
    sudo docker rm $RESP
  fi

  # Remove unused images
  sudo docker image prune -f

  # Remove unused volumes
  RESP=$(sudo docker volume ls -qf dangling=true)
  if [ ! -z "$RESP" ]; then
    sudo docker volume rm $RESP
  fi
  sudo docker volume ls -qf dangling=true | xargs -r sudo docker volume rm

  # Remove unsed images
  RESP=$(sudo docker images --filter "dangling=true" -q --no-trunc)
  if [ ! -z "$RESP" ]; then
    sudo docker rmi $RESP
  fi
  RESP=$(sudo docker images | grep "none" | awk '/ / { print $3 }')
  if [ ! -z "$RESP" ]; then
    sudo docker rmi $RESP
  fi

  # Remove exited container
  RESP=$(sudo docker ps -qa --no-trunc --filter "status=exited")
  if [ ! -z "$RESP" ]; then
    sudo docker rm $RESP
  fi
}

#
# Start docker container
#
function start {
  RESP=$(sudo docker ps -qa --no-trunc --filter "name=$CONTAINER")
  if [ ! -z "$RESP" ]; then
    sudo docker stop $RESP
    sudo docker rm $RESP
  fi

  sudo docker run -d \
    --add-host=$HOST:127.0.0.1 \
    --hostname=$HOST \
    --ip $IP \
    --name $CONTAINER \
    --network $NETWORK \
    --publish $PORT \
    --rm=true \
    --volume $VOLUME \
    $CONTAINER
}



# Check if no arguments given
if [ -z "$1" ]; then
  help
  exit 1
fi

# Check that all given variables are valid
for VAR in "$@"; do
  if [[ ! $VAR == @(access|build|clean|rebuild|start) ]]; then
    help
    exit 1
  fi
done

# Execute variables in given order
for VAR in "$@"; do
  if [ "$VAR" == "access" ]; then
    access
  elif [ "$VAR" == "build" ]; then
    build
  elif [ "$VAR" == "clean" ]; then
    clean
  elif [ "$VAR" == "rebuild" ]; then
    rebuild
  elif [ "$VAR" == "start" ]; then
    start
  fi
done
