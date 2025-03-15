# Containerlab On AWS

Containerlab on AWS enables users to deploy [Containerlab](https://containerlab.dev/) on AWS, providing a scalable alternative to local PC environments limited by CPU or RAM. This project automates the creation of AWS infrastructure, including a VPC, Internet Gateway, and an EC2 instance with a public IP. The setup ensures internet connectivity for AWS "Instance Connect" and access from the user's public IP. An Ansible script is used to update the environment, install necessary packages, and upload containerlab topology files or Docker images.

## Installation & Configuration

*Currently this project is linux host only.*

Installation:

1. git clone this project.
1. Install [OpenTofu](http://opentofu.org) (Terraform fork):

    ```shell
    alias tofu='podman run --rm -it --workdir=/srv/workspace --mount type=bind,source=.,target=/srv/workspace -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION ghcr.io/opentofu/opentofu:latest'
    ```

1. Install the [AWS CLI](https://aws.amazon.com/cli/)

    ```shell
    alias aws='podman run --rm -it --mount type=bind,source=$HOME/.aws,target=/root/.aws --mount type=bind,source=$(pwd),target=/aws docker.io/amazon/aws-cli:latest'
    ```

1. Install necessary build tools, [Python >=3.9](https://www.python.org/downloads/) and libffi-dev:

    ```shell
    sudo apt-get update
    sudo apt-get install build-essential python3-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev zlib1g-dev python3-pip
    ```

1. Create a virtual environment:

    ```shell
    python3 -m venv venv
    source venv/bin/activate
    # Per issue with pyyaml 6.0 and cython 3.0.0: https://github.com/yaml/pyyaml/issues/724
    pip install "cython<3.0.0" && pip install --no-build-isolation pyyaml==6.0
    pip install --only-binary :all: cffi
    pip install -r requirements.txt
    ```

Configuration:

1. Configure the AWS CLI with permissions.  AWS user must have at least enough privilages to create a VPC, Subnet, NACL, Security Group, Internet Gateway, and an EC2 instance.
1. Configure the AWS CLI

    ```shell
    mkdir -p ~/.aws
    aws configure

    AWS Access Key ID [None]: YOUR_ACCESS_KEY_HERE
    AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY_HERE
    Default region name [None]: YOUR_PREFERRED_REGION
    Default output format [None]: json

    # Verify AWS CLI Configuration
    aws sts get-caller-identity
    ```

1. Review the ```vars.yml``` file, this file contains the settings that will be applied to the infrastructure.  For instance if you want this deployed in us-east-2, you would set that here, if you wanted a different AMI or instance size you would set that here.  Review that file before deploying to ensure you deploy the infrastructure with the settings you prefer.

    ```shell
    <Truncated>
    region: us-east-2
    ec2_instance_type: t2.medium
    ami_id: ami-024e6efaf93d85776
    <Truncated>
    ```

## Usage

With the required software installed and configured it's time to prepare to build the infrastructure and upload the required software.

1. If you have a containerlab topology file that you'd like to upload as part of the work flow, include it in the ```cl_clab``` folder where ansible will automatically pick it up.
1. If you have docker images that need to be uploaded because the image is not publically available from docker or because you have a special usecase, include it in the ```cl_images``` folder and it will automatically upload those images.
1. Build the infrastructure:

    ```shell
    tofu init
    tofu plan
    tofu apply
    # OR
    tofu apply --auto-approve
    ```

    Besides building the infrastucture Terraform/OpenTofu is also performing a few things behind the scenes.  It creates a key pair for the EC2 instance and places it in the local directory so ansible and the end user can manage the instance.  *KEEP THIS SAFE, THIS GRANTS ACCESS TO A USER WITH SUDO PRIVILAGES*. In addition, a shell file is made executable along with the public IP address of the instance so ansible knows how to log into it.  Lastly a custom user has been created so no matter which instance type you choose the username is ubiquitous across environments.
1. Configure the environment

    ```shell
    # This should already be activated, but if not activate the venv again
    source venv/bin/activate
    ansible-playbook cl_lab/srl2/site.yml
    ```

    This command will run the ansible playbook which will update the environment, install necessary packages, and upload any containerlab topology files or docker images.
1. Log into your EC2 Instance and run your topology!

    ```shell
    ssh -i containerlab-key.pem containerlabuser@WHATEVER_IP_ADDRESS_IS_ASSOCIATED_WITH_EC2
    cd containerlab_environment/
    sudo containerlab deploy -t YOUR_TOPOLOGY_FILE_NAME.yml
    ```

## Troubleshooting

- Ansible is not recognized or is throwing errors.
  - Make sure your virtual environment is still activated after installing the requirements.

    ```shell
    source venv/bin/activate
    ```

- Containerlab command erroring
  - Deployments and destroys require sudo, ensure you're running commands as sudo.
- CPU virtualization support not available error
  - This issue is seen when trying to deploy vrnetlab container images (Cisco/Juniper/vEOS) with containerlab on regular VM based EC2 instances in AWS
    - The root cause is AWS VMs not supporting nested virtualisation - bare metal servers need to be used instead
  - Workaround: Change `ec2_instance_type` variable in **vars.yml** file to `c5.metal`
    - For more information refer to this GitHub issue: [Issue 5](https://github.com/friday963/containerlab_on_aws/issues/5)
