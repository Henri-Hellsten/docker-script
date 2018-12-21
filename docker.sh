#!/bin/bash

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
  echo "AWS:"
  echo "  build-aws         Build docker container for AWS"
  echo "  deploy            Deploy docker container to AWS ECS"
  echo "  push              Push docker container to AWS ECR"
}

#
# Include variables
#
source docker-config.sh

#
# Check variables
#
function check {
  # Go thru given variables and check if missing
  MISSING=()
  for VAR in "$@"; do
    if [ -z "${!VAR}" ]; then
      MISSING+=($VAR)
    fi
  done

  # Check if missing one of the given global variables
  if [ ${#MISSING[@]} -gt 0 ]; then
    echo "missing docker-config.sh variable(s) ${MISSING[@]}"
    exit 1
  fi
}

#
# Access docker container
#
function access {
  # Required variables
  check "CONTAINER"

  sudo docker exec -it $CONTAINER /bin/bash
}

#
# Build docker container
#
function build {
  # Required variables
  check "CONTAINER"

  # Check if build params given
  PARAMS=""
  if [ ! -z "$@" ]; then
    PARAMS=$@
  fi

  # Build docker container
  sudo docker build $PARAMS -t $CONTAINER:latest .
}

#
# Build docker container for AWS
#
function build-aws {
  # Required variables
  check "CODE"

  # Pack code to get it inside docker build enviroment
  echo "Packing code..."
  tar -zcf data/code.tar.gz -C $CODE

  # Build docker without cache
  build "--no-cache"

  # Remove packed code so it won't get reused accidentally
  rm -rf data/code.tar.gz
}

#
# Re-build docker container
#
function rebuild {
  build "--no-cache"
}

#
# Clean docker container
#
function clean {
  # Required variables
  check "CONTAINER"

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
  # Required variables
  check "CONTAINER" "HOST" "IP" "NETWORK" "PORT"

  RESP=$(sudo docker ps -qa --no-trunc --filter "name=$CONTAINER")
  if [ ! -z "$RESP" ]; then
    sudo docker stop $RESP
    sudo docker rm $RESP
  fi

  # Check optional params
  SET_VOLUME=""
  if [ ! -z $VOLUME ]; then
    SET_VOLUME="--volume $VOLUME"
  fi

  sudo docker run -d \
    --add-host=$HOST:127.0.0.1 \
    --hostname=$HOST \
    --ip $IP \
    --name $CONTAINER \
    --network $NETWORK \
    --publish $PORT \
    --rm=true \
    $SET_VOLUME \
    $CONTAINER
}



#
# Deploy docker container to AWS
#
function deploy {
  # Required variables
  check "CLUSTER" "SERVICE"

  # Call force deployment for docker service
  aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment
}

#
# Push docker container to AWS
#
function push {
  # Required variables
  check "CONTAINER" "AWSREPO"

  # Login to AWS
  sudo $(aws ecr get-login --no-include-email)
  # Tag container properly for AWS
  sudo docker tag $CONTAINER:latest $AWSREPO/$CONTAINER:latest
  # Push container
  sudo docker push $AWSREPO/$CONTAINER:latest
}

# Check if no arguments given
if [ -z "$1" ]; then
  help
  exit 1
fi

# Check that all given variables are valid
for VAR in "$@"; do
  if [[ ! $VAR == @(access|build|build-aws|clean|rebuild|start|deploy|push) ]]; then
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
  #
  # AWS
  #
  elif [ "$VAR" == "build-aws" ]; then
    build-aws
  elif [ "$VAR" == "deploy" ]; then
    deploy
  elif [ "$VAR" == "push" ]; then
    push
  fi
done
