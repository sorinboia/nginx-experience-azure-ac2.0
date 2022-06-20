resource "azurerm_public_ip" "controller_pip" {
  name = "controller_pip"
  location = var.controller_location
  resource_group_name = azurerm_resource_group.az_resourcegroup.name
  allocation_method = "Dynamic"
  sku = "Basic"
}

resource "azurerm_network_interface" "controller_vm1nic" {
  name = "controller-vm1-nic-${random_id.random-string.dec}"
  location = var.controller_location
  resource_group_name = azurerm_resource_group.az_resourcegroup.name
  ip_configuration {
    name = "ipconfig1"
    subnet_id = azurerm_subnet.frontendsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.controller_pip.id
  }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "controller-${random_id.random-string.dec}"
  location              = var.controller_location
  resource_group_name   = azurerm_resource_group.az_resourcegroup.name
  network_interface_ids = [azurerm_network_interface.controller_vm1nic.id]
  vm_size               = "standard_D8ads_v5"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb = "100"
  }
  os_profile {
    computer_name  = "controller"
    admin_username = "ubuntu"
    admin_password = "Password1234!"
    custom_data = <<-EOF
      #!/bin/bash
      apt-get update
      swapoff -a
      ufw disable
      apt-get install socat ebtables conntrack jq -y   
      wget https://sorinnginx.s3.eu-central-1.amazonaws.com/apim-controller-installer-3.19.4.tar.gz -O /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      export HOME=/home/ubuntu
      #/home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email admin@nginx.com --admin-password Admin2021 --self-signed-cert --auto-install-docker --configdb-volume-type local --tsdb-volume-type local
      runuser -l ubuntu -c 'host_ip=$(curl -s ifconfig.me) && /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email admin@nginx.com --admin-password Admin2021 --self-signed-cert --auto-install-docker --configdb-volume-type local --tsdb-volume-type local'
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "admin@nginx.com","password": "Admin2021"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLUVGRDJCRDdCNzk4QjQ5N0NGODIzRUVFMzg3QURFQjg0IgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLUVGRDJCRDdCNzk4QjQ5N0NGODIzRUVFMzg3QURFQjg0Cld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNaTB3TnkweE5sUXdOVG8wT0Rvd015NHlPVEU0T0RoYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURReE5EZ3NJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpVkRBd01ERXlNell3TXlJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0luUnlhV0ZzSWl3Z0NpQWcKSUNBZ0lDQWdJblpsY25OcGIyNGlPaUF4Q2lBZ0lDQjlMQ0FLSUNBZ0lIc0tJQ0FnSUNBZ0lDQWlaWGh3YVhKNUlqb2dJakl3TWpJdApNRGN0TVRaVU1EVTZORGc2TURNdU1qa3hOak0zV2lJc0lBb2dJQ0FnSUNBZ0lDSnNhVzFwZEhNaU9pQTVPVGs1T1N3Z0NpQWdJQ0FnCklDQWdJbXhwYldsMGMxOWhjR2xmWTJGc2JITWlPaUF5TURBd01EQXdNQ3dnQ2lBZ0lDQWdJQ0FnSW5CeWIyUjFZM1FpT2lBaVRrZEoKVGxnZ1EyOXVkSEp2Ykd4bGNpQkJVRWtnVFdGdVlXZGxiV1Z1ZENJc0lBb2dJQ0FnSUNBZ0lDSnpaWEpwWVd3aU9pQTBNVFE0TENBSwpJQ0FnSUNBZ0lDQWljM1ZpYzJOeWFYQjBhVzl1SWpvZ0lsUXdNREF4TWpNMk1ETWlMQ0FLSUNBZ0lDQWdJQ0FpZEhsd1pTSTZJQ0owCmNtbGhiQ0lzSUFvZ0lDQWdJQ0FnSUNKMlpYSnphVzl1SWpvZ01Rb2dJQ0FnZlFwZAoKLS0tLS0tRUZEMkJEN0I3OThCNDk3Q0Y4MjNFRUUzODdBREVCODQKQ29udGVudC1UeXBlOiBhcHBsaWNhdGlvbi94LXBrY3M3LXNpZ25hdHVyZTsgbmFtZT0ic21pbWUucDdzIgpDb250ZW50LVRyYW5zZmVyLUVuY29kaW5nOiBiYXNlNjQKQ29udGVudC1EaXNwb3NpdGlvbjogYXR0YWNobWVudDsgZmlsZW5hbWU9InNtaW1lLnA3cyIKCk1JSUZ2QVlKS29aSWh2Y05BUWNDb0lJRnJUQ0NCYWtDQVFFeER6QU5CZ2xnaGtnQlpRTUVBZ0VGQURBTEJna3EKaGtpRzl3MEJCd0dnZ2dNek1JSURMekNDQWhlZ0F3SUJBZ0lKQUlNenBYUUhwU3lhTUEwR0NTcUdTSWIzRFFFQgpDd1VBTUM0eEVqQVFCZ05WQkFvTUNVNUhTVTVZSUVsdVl6RVlNQllHQTFVRUF3d1BRMjl1ZEhKdmJHeGxjaUJEClFTQXhNQjRYRFRFNE1EVXhNVEV5TVRNMU1Wb1hEVEl5TURVeE1ERXlNVE0xTVZvd0xqRVNNQkFHQTFVRUNnd0oKVGtkSlRsZ2dTVzVqTVJnd0ZnWURWUVFEREE5RGIyNTBjbTlzYkdWeUlFTkJJREV3Z2dFaU1BMEdDU3FHU0liMwpEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURSVmNSRzFuV0tUMk8vc3JyNllmc01nN0VDeXBHaHJoM3JEc0ZkCkV1cEs1UWRRN01SLzNIa2I5NERZOHg5TGNJZDVVY2ZxVzFaWXVzeGdaRk5seDlvcG1ZZmluZmlzV2hxcmV1WUoKTWpwVU82SC81Ly9ZUTZObFdOS0FHQzJqejZMbEdEK1cwMmpBUzNkR1BjM0V5Ti9hZzd5VXNYSm1KZXZFVCt1MApxbFFyNEFwWWp2Z1dTdjRtaVdCY2pmMW0xM3M1RlQwYXVsKzFFSXpIUVhLaitsYUdMSE1Lc2FGdDFHaC9xMHlaCmhLTXlyaXBZTERqR1FlTVFvc3g1bGFBQWdKN04zTG54UW56UmlBNkN0OUJGYm9wLzBGN1Q2djY0QXFCUEduNEIKbXpvbEN2ZXNZZ2lrK2p1Q0RsTU9GTWxVeHJxU3oxQXZRZVBzOGdZcW9hQXJ0U2NUQWdNQkFBR2pVREJPTUIwRwpBMVVkRGdRV0JCUVNhV0dtV3FzbU1zc3hXcCtYamx6a3d5bjhYVEFmQmdOVkhTTUVHREFXZ0JRU2FXR21XcXNtCk1zc3hXcCtYamx6a3d5bjhYVEFNQmdOVkhSTUVCVEFEQVFIL01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ3AKN3phRDFOdk0xRFRFUHprQ05vOEIwbVA4ZDE0S3VleWFZcFYvbXdNS2tBa3NsTHZwdzE5ai85d1p4OEZtMlpGTgpUTkJUUmIvbXBIdGZOUENQSlkxM2NtZVFKNkdQTUE1eGxnL0lMd0lic083bEp6NGxGbFhZYU1qaCsrR3ZFTy9rClhFbC9OVUZ0TnFtcmI0c3pYSjJTaGJyMkoxaDB6VEZuazJ3MVgzcFZwaWsyVk5qSmY3dVQ2dDVUTlpXcERIRnQKS1c0YWZJeHdFNXVzVXFLOERBd2JyS2sxRkIreEtNV05wVEtYMXlzNk4rRmZlVXljNkh1WjNKRlczQjZYTTMrOQpMOXJlSmxpMlRRa2JvaUJNUElxS2RSRlRaL2xkYTR0d01uaURFRjlZZE03ekJ0elZmeFRpZjdReWJ3aWd3L1AxCmhUSUZRaWkzUElqS3ZDcmR3RkJmTVlJQ1RUQ0NBa2tDQVFFd096QXVNUkl3RUFZRFZRUUtEQWxPUjBsT1dDQkoKYm1NeEdEQVdCZ05WQkFNTUQwTnZiblJ5YjJ4c1pYSWdRMEVnTVFJSkFJTXpwWFFIcFN5YU1BMEdDV0NHU0FGbApBd1FDQVFVQW9JSGtNQmdHQ1NxR1NJYjNEUUVKQXpFTEJna3Foa2lHOXcwQkJ3RXdIQVlKS29aSWh2Y05BUWtGCk1ROFhEVEl5TURZeE5qQTFORGd3TTFvd0x3WUpLb1pJaHZjTkFRa0VNU0lFSUd5OHNFK3FLT0p2d01EaWR5L1YKUThUenJvNURtL21hd0NQcHdQUGZQQ3VmTUhrR0NTcUdTSWIzRFFFSkR6RnNNR293Q3dZSllJWklBV1VEQkFFcQpNQXNHQ1dDR1NBRmxBd1FCRmpBTEJnbGdoa2dCWlFNRUFRSXdDZ1lJS29aSWh2Y05Bd2N3RGdZSUtvWklodmNOCkF3SUNBZ0NBTUEwR0NDcUdTSWIzRFFNQ0FnRkFNQWNHQlNzT0F3SUhNQTBHQ0NxR1NJYjNEUU1DQWdFb01BMEcKQ1NxR1NJYjNEUUVCQVFVQUJJSUJBR1dtVURoWmh6OGR1clZPckEySHVXeDFOUE56eGo0NGdDZlpHQk1QcWRqUwpOcGUvaVBIdHRGNEM1NG1GMHFCaXhib0VVZU84ZTBJVFRPUFZYQWxScG14MCs3RVQzUTY2aHc1ajZSOVg0K2RBCndIcG5DeXBrMmFsWFM1cncvNjJkK21NVUJZaXB6MHRqL3ByMWpKdUVJVUk3QURLQ3J1MndzcitjZG55SlpCM20KblJ3NzROZlBXZFR5VktHU0I0akRXVnoyNG5FcnF3SUlNUnFLSlVLVmIra1FtYTh5OGF6ZjBUOTA3dmZTemZhZgpVZWs4MjAwb1RUMlJuZ0Q5cUdlYmc3ZWt0WjVBeGRxb3dGM3owOUlrMUJzUXlIRzNBUHYwYzFZZ3h6ajByYThECi9odnp3MGVUMk1IYlNYKzhzNnZaVW52OEVROFBueXQra1ZHS0RHeU0reDQ9CgotLS0tLS1FRkQyQkQ3Qjc5OEI0OTdDRjgyM0VFRTM4N0FERUI4NC0tCgo="}'
    EOF
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
