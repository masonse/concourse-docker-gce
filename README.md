#README.md

This repo provides a method to use [Terraform](https://www.terraform.io/) to configure Google Compute Engines to deploy [Concourse.ci](http://concourse.ci/docker-repository.html).

You'll need to:

1. Install Terraform on your local or deployment system, 
2. Establish a Google Compute Engine project. 
  * Download the [GCE service account](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances) .json file.
3. Create [ssh keys](https://cloud.google.com/compute/docs/instances/connecting-to-instance) for the local account terraform which is used to ssh to the GCE VMs. The public key should be added to the meta-data