# ethereum-consortium-orchestration
PowerShell scripts and ARM template parameter files to orchestrate the deployment of an Ethereum consortium blockchain including additional components for each member.

## Note about Docker Images
For these templates to work, you will need to generate two docker images, one for the dashboard node and one for tx / mining nodes. Dockerfiles are available for both but you must build and push the Docker images to a repository.

### Dockerfiles
A dockerfile for the txNodeDockerImage and minerNodeDockerImage can be found at:

https://github.com/mormond/hackfest-images/blob/master/ethereum-node/geth/Dockerfile  

A dockerfile for the dashboardDockerImage can be found at:

https://github.com/mormond/hackfest-images/blob/master/eth-stats-dashboard/Dockerfile 

Set the txNodeDockerImage / minerNodeDockerImage / dashboardDockerImage via the ARM template params file.

### Building and pushing dockerfiles
There is a guide at: https://docs.docker.com/engine/getstarted/step_one/
