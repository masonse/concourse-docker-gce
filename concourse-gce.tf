// Configure the Google Cloud provider
provider "google" {
  credentials = "${file("gce_account.json")}"
  project     = "braided-turbine-145521"
  region      = "us-central1"
}


#Create 1 centos7 nodes
resource "google_compute_instance" "default" {
  count = 1

  name         = "tf-cicd-${count.index}"
  machine_type = "n1-standard-1"
  zone         = "us-central1-b"
  tags         = ["concourse-node", "http-server"]

  connection {
    type        = "ssh"
    agent       = false
    user        = "terraform"
    timeout     = "5m"
    private_key = "${file("ssh/terraform")}"
  }

  disk {
    image = "centos-cloud/centos-7"
    size = "50"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leave this block empty to generate a new 
      // external IP and assign it to the machine
    	}
	}


#Add Docker Yum Repo
	provisioner "remote-exec" {
		script = "add-docker-yum-repo.sh"
	}

#Install Docker from Yum Repo
	provisioner "remote-exec" {
		inline = [
			"sudo yum -y install docker-engine",
			"sleep 10",
			"sudo systemctl enable docker.service",
			"sleep 10",
			"sudo systemctl start docker"
		]
	}


#Install docker-compose
	provisioner "remote-exec" {
		inline = [
		"curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /tmp/docker-compose",
		"sudo mv /tmp/docker-compose /usr/local/bin/docker-compose",
		"sudo chmod +x /usr/local/bin/docker-compose"

		]
	 	
	} 
		
#Create Keys for Concourse

    provisioner "remote-exec" {
		script = "make-concourse-keys.sh"
    }

	
#Set external URL for concourse and add our user to the docker user group
	provisioner "remote-exec" {
		inline = [
# 5 hours to get this POS line....
			"echo '${format("export CONCOURSE_EXTERNAL_URL=http://%s", self.network_interface.0.access_config.0.assigned_nat_ip)}' >> .bashrc",
      "sudo usermod -aG docker $(whoami)"
			
		]
	}


#Copy docker-compose.yml
    provisioner "file" {
        source = "docker-compose.yml"
        destination = "docker-compose.yml"
    }  

#Start up concourse
	provisioner "remote-exec" {
		inline = [
		"docker-compose up"
		]
	}

}

resource "google_compute_firewall" "default" {
  name    = "tf-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["concourse-node"]
}
