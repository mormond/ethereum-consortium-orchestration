# ethereum-consortium-orchestration
PowerShell scripts and ARM template parameter files to orchestrate the deployment of an Ethereum consortium blockchain including additional components for each member.

## Dependencies

### Platform
All of the following steps were validated on a Windows 10 client OS. If you want to deploy from another platform, you will need to ensure you have all the relevant dependencies installed.

### Github Repo
The deployment uses the templates at https://github.com/EthereumEx/ethereum-arm-templates - this repo will need to be forked for some minor changes to be made (see below). This is required because we chose not to redistribute the code in this repo.

### Docker Images
For these templates to work, you will need to generate two docker images, one for the dashboard node and one for tx / mining nodes. Dockerfiles are available for both but you must build and push the Docker images to Docker Hub (see below).

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
[119]      "allowedValues": [
[120]         "ethereumex/eth-stats-dashboard:latest"
[121]      ]
```
```json
[124]      "defaultValue": "ethereumex/geth-node:latest",
...
   *[126]      "allowedValues": [
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
   * Commit your local changes
      * __git add \*__
      * __git commit -m 'Updating templates'__
   * Push your changes to the GitHub repo
   * __git push origin my-branch-name__ 

### 2/ Create the required Docker images
For this step, you will need Docker installed. As we are working with Linux containers on a Windows client, you will need to install Docker for Windows: https://docs.docker.com/docker-for-windows/install/.

If you aren't familiar with Docker, a guide for building and pushing dockerfiles is available at: https://docs.docker.com/engine/getstarted/step_one/. In particular, the section on "Containers" which describes Docker files, building and pushing to a remote registry.
#### Dockerfiles
* A dockerfile for the txNodeDockerImage and minerNodeDockerImage can be found at: 
https://github.com/mormond/hackfest-images/blob/master/ethereum-node/geth/Dockerfile  
* A dockerfile for the dashboardDockerImage can be found at:     
https://github.com/mormond/hackfest-images/blob/master/eth-stats-dashboard/Dockerfile 

#### Docker images
Build the dockerfiles above and push the images to Docker Hub (the Docker public registry https://hub.docker.com/).

The txNodeDockerImage / minerNodeDockerImage / dashboardDockerImage location will be set via the ARM template params file (see below).

### 3/ Clone and customise the deployment script parameters
1. Clone this repo to your local machine (https://github.com/mormond/ethereum-consortium-orchestration)
2. There are two template params files. One is for a founder deployment (ie creating a new blockchain network), the other is to add a new particpant to an existing network. Pick whichever is the right one for the deployment type you intend to do. 
   * .\\ethereum-consortium-params\\__template.consortium.params.json__ (for a new deployment)
   * .\\ethereum-consortium-params\\__template.consortium.params.participant1.json__ (to add a member to an existing deployment)
   * We will walk through a new deployment using __template.consortium.params.json__ but the process is very similar for both.
3. Firstly we will need to create an account
   * Navigate to My Ether Wallet: http://myetherwallet.com
   * Type in a password that will be used to secure the file generated
   * Download the Keystore file. We'll need this later.
   * Copy the address. Make sure the address is prefixed with '0x' (eg 0x0000000000000000000000000000000000000000)
4. Update the genesisJson in __template.consortium.params.json__
    * Replace the 0x0000000000000000000000000000000000000000 in the alloc section of the json with the address that you created above.
    * Update the nonce with a valid hex value
5. In __template.consortium.params.json__, as a minimum we need to set the following values:
   * consortiumName - a short string to identify resources in the consortium
   * contentRootOverride - https://raw.githubusercontent.com/[my-repo-name]/ethereum-arm-templates/[my-branch-name]/ethereum-consortium
   * dashboardDockerImage - Docker Hub image name (eg username/repository:tag)
   * dashboardSecret - a shared secret used to authenticate with the dashboard
   * genesisJson - the genesis JSON created above
   * gethNetworkId - an integer used for uniqueness. See the Ethereum documentation for more details
   * members - update the minerAddress to match the account address in the genesisJson
   * minerNodeDockerImage - Docker Hub image name (eg username/repository:tag)
   * sshPublicKey - use something like puttygen to generated this and save the file somewhere safe
   * txNodeDockerImage - Docker Hub image name (eg username/repository:tag)
   * username
5. An example (complete) template params file is located at .\\ethereum-consortium-params\\__template.consortium.params.example.json__
6. Now we have a populated parameters file, we can kick off a deployment
   * Open a PowerShell command prompt
   * cd to the __orchestration-scripts__ folder
   * __.\\deploy.consortium.ps1__ will start a deployment and prompt for missing (script) parameter values
      * The PowerShell script automatically looks for the relevant parameters file in the ethereum-consortium-params folder
   * For example, the following would start a new founder deployment, creating a new resource group called "test123" in the west europe region
      * __.\\deploy.consortium.ps1 -rgName "test123" -location westeurope -chosenDeploymentType founder__
   * There are a number of mandatory parameter values. All the paramaters are documented in the deploy.consortium PowerShell script
