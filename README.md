# ethereum-consortium-orchestration
PowerShell scripts and ARM template parameter files to orchestrate the deployment of an Ethereum consortium blockchain including additional components for each member.

## Dependencies

### Github Repo
The deployment uses the templates at https://github.com/EthereumEx/ethereum-arm-templates - this repo will need to be forked for some minor changes to be made (see below). This is required because we chose not to redistribute the code in this repo.

### Docker Images
For these templates to work, you will need to generate two docker images, one for the dashboard node and one for tx / mining nodes. Dockerfiles are available for both but you must build and push the Docker images to a repository (see below).

## Steps to deploy using these templates

### 1/ Create the modified fork of ethereum-arm-templates repo

1. Fork the Github repo mentioned above https://github.com/EthereumEx/ethereum-arm-templates.git 
2. Clone the fork to your local machine
3. We need version Release-v1.0.0
    * __git checkout Release-v1.0.0__
    * __git checkout -b 'my-branch-name'__
4. Open the following files in your favourite text editor
    * .\\ethereum-consortium\\__template.consortium.custom.json__
    * .\\ethereum-consortium\\__template.consortium.json__
    * .\\ethereum-consortium\\__template.consortiumMember.json__
5. Make the following edits

In .\\ethereum-consortium\\__template.consortium.custom.json__ remove the following lines and any redundant trailing commas that result 

Tip: It's easier to remove lines from the bottom up so that line numbers remain consistent with the instructions

```json
[121]      "defaultValue": "ethereumex/geth-node:latest",
...
[125]      "defaultValue": "ethereumex/geth-node:latest",
```

In .\\ethereum-consortium\\__template.consortium.json__ remove the following lines and any redundant trailing commas that result 

```json
[124]      "defaultValue": "ethereumex/geth-node:latest",
...
[126]      "allowedValues": [
[127]        "ethereumex/geth-node:latest",
[128]        "ethereumex/parity-node:latest"
[129]      ]
...
[133]      "defaultValue": "ethereumex/geth-node:latest",
...
[135]      "allowedValues": [
[136]        "ethereumex/geth-node:latest"
[137]      ]	  
```

In .\\ethereum-consortium\\__template.consortiumMember.json__ remove the following lines and any redundant trailing commas that result 

```json
[120]      "defaultValue": "ethereumex/geth-node:latest",
...
[127]      "defaultValue": "ethereumex/geth-node:latest",	  
```

6. Push the local branch to your forked GitHub repo
    * __git push origin 'my-branch-name'__ 

### 2/ Create the required Docker images
For this step, you will need Docker installed. Follow this link for installation instructions: https://docs.docker.com/engine/installation/

If you aren't familiar with Docker, a guide for building and pushing dockerfiles is available at: https://docs.docker.com/engine/getstarted/step_one/
#### Dockerfiles
* A dockerfile for the txNodeDockerImage and minerNodeDockerImage can be found at: 
https://github.com/mormond/hackfest-images/blob/master/ethereum-node/geth/Dockerfile  
* A dockerfile for the dashboardDockerImage can be found at:     
https://github.com/mormond/hackfest-images/blob/master/eth-stats-dashboard/Dockerfile 

#### Docker images
Build the dockerfiles above and push the images to a suitable registry (eg the Docker public registry).

The txNodeDockerImage / minerNodeDockerImage / dashboardDockerImage location will be set via the ARM template params file (see below).

### 3/ Clone and customise the deployment script parameters
1. Clone this repo to your local machine (https://github.com/mormond/ethereum-consortium-orchestration)
2. There are two template params files. One is for a founder deployment (ie creating a new blockchain network), the other is to add a new particpant to an existing network. Pick whichever is the right one for the deployment type you intend to do. 
   * .\\ethereum-consortium-params\\__template.consortium.params.json__ (for a new deployment)
   * .\\ethereum-consortium-params\\__template.consortium.params.participant1.json__ (to add a member to an existing deployment)
   * We will walk through a new deployment using __template.consortium.params.json__ but the process is very similar for both.
3. Firstly we will need to create
   * A public / private key pair (keystore file)
   * Suitable values for the genesis JSON
   * Suitable values for the member JSON
4. To generate these, follow instructions at:
   * https://github.com/mormond/ethereum-arm-templates/tree/master/ethereum-consortium 
   * and specifically https://github.com/mormond/ethereum-arm-templates/blob/master/ethereum-consortium/docs/setupWalkthrough.md 
   * These walk you through creating and account using http://myetherwallet.com/ and generating the genesis JSON and member JSON content. However, rather than deploying the template now, we will capture these values in a parameter file and provide this to a deployment script.
   * Note that the template files in this repo already have some of these values predefined as a starting point 
5. In __template.consortium.params.json__, as a minimum we need to set the following values:
   * consortiumName
   * contentRootOverride - https://raw.githubusercontent.com/my-repo-name/ethereum-arm-templates/my-branch-name/ethereum-consortium
   * dashboardDockerImage - URL to the location of the Docker Image created above
   * dashboardSecret
   * genesisJson - the genesis JSON created above
   * gethNetworkId
   * members - the members JSON created above
   * minerNodeDockerImage - URL to the location of the Docker Image created above
   * sshPublicKey
   * txNodeDockerImage - URL to the location of the Docker Image created above
   * username
6. An example (complete) template params file is located at .\\ethereum-consortium-params\\__template.consortium.params.example.json__
7. Now we have a populated parameters file, we can kick off a deployment
   * cd to the __orchestration-scripts__ folder
   * __.\\deploy.consortium.ps1__ will start a deployment and prompt for missing (script) parameter values
      * The PowerShell script automatically looks for the relevant parameters file in the ethereum-consortium-params folder
   * For example, the following would start a new founder deployment, creating a new resource group called "test123" in the west europe region
      * __.\\deploy.consortium.ps1 -rgName "test123" -location westeurope -chosenDeploymentType founder__
