#
# Example config
#

# Container name
CONTAINER="container-name"
# Container internal hostname (set in /etc/hosts)
HOST="container.local"
# Container docker network to use
NETWORK="containers"
# Container IP
IP="172.18.1.10"
# Container and local bind ports
PORT="80:80"

#
# Local development variables
#

# Container and local machine mount point (OPTIONAL)
VOLUME="/var/www:/var/www"

#
# AWS publishing variables
#

# Code path on local machine to be copied to container
# NOTE! If add path first and then actual directories where the code resides!
CODE="/var/www api client"
# AWS ECR repository address
AWSREPO="1234567890.dkr.ecr.eu-central-1.amazonaws.com"
# AWS Cluster name
CLUSTER="container-cluster"
# AWS Service name
SERVICE="container-service"
