
locals {
  tags = split(",", var.GREEN_BERET_GCP_TAGS)
}

resource "google_compute_instance" "green-beret" {
  name         = var.GREEN_BERET_INSTANCE_NAME
  machine_type = var.GREEN_BERET_GCP_INSTANCE_TYPE
  zone         = var.GREEN_BERET_GCP_ZONE

  tags = concat(local.tags, [var.GREEN_BERET_GCP_FIREWALL_TAG])

  boot_disk {
    initialize_params {
      image = var.GREEN_BERET_GCP_BOOT_DISK_IMAGE
	  size  = 50
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    email  = var.GREEN_BERET_GCP_SERVICE_ACCOUNT
    scopes = split(",", var.GREEN_BERET_GCP_SERVICE_ACCOUNT_SCOPES)
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.GREEN_BERET_GCP_PUBLIC_KEY_FILEPATH)}"
  }

  allow_stopping_for_update = true

  depends_on = [google_compute_firewall.ssh-mosh-server]
}

resource "google_compute_firewall" "ssh-mosh-server" {
  name    = "${var.GREEN_BERET_INSTANCE_NAME}-allow-ssh-mosh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "udp"
    ports    = ["60000-61000"]
  }

  // Allow traffic from everywhere to instances with target_tags
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.GREEN_BERET_GCP_FIREWALL_TAG]
}

output "instance-id" {
  value = google_compute_instance.green-beret.instance_id
}

output "instance-ip" {
  value = google_compute_instance.green-beret.network_interface.0.access_config.0.nat_ip
}

resource "null_resource" "instance_config" {
  triggers = {
    instance_id = google_compute_instance.green-beret.instance_id
  }

  connection {
    host        = google_compute_instance.green-beret.network_interface.0.access_config.0.nat_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.GREEN_BERET_GCP_PRIVATE_KEY_FILEPATH)
  }

  provisioner "file" {
    source      = "../../instance_config/setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "file" {
    source      = "../../instance_config/bashrc"
    destination = "/tmp/bashrc"
  }

  provisioner "file" {
    source      = "../../instance_config/vimrc"
    destination = "~/.vimrc"
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /tmp/setup.sh && /tmp/setup.sh",
              "cat /tmp/bashrc >> ~/.bashrc"]
  }
}
