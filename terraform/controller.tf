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
  vm_size               = "standard_E8a_v4"

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
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLUIyOUE5QjcwNDVBMjE4NUNDODg4MkMzMzE1MjFDRjUxIgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLUIyOUE5QjcwNDVBMjE4NUNDODg4MkMzMzE1MjFDRjUxCld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNaTB3TkMwd01sUXdOem95TkRvd015NHhNREF3TlRsYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURRd016Z3NJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpVkRBd01ERXlNRFkyTlNJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0luUnlhV0ZzSWl3Z0NpQWcKSUNBZ0lDQWdJblpsY25OcGIyNGlPaUF4Q2lBZ0lDQjlMQ0FLSUNBZ0lIc0tJQ0FnSUNBZ0lDQWlaWGh3YVhKNUlqb2dJakl3TWpJdApNRFF0TURKVU1EYzZNalE2TURNdU1EazVOVGN5V2lJc0lBb2dJQ0FnSUNBZ0lDSnNhVzFwZEhNaU9pQTVPVGs1T1N3Z0NpQWdJQ0FnCklDQWdJbXhwYldsMGMxOWhjR2xmWTJGc2JITWlPaUF5TURBd01EQXdNQ3dnQ2lBZ0lDQWdJQ0FnSW5CeWIyUjFZM1FpT2lBaVRrZEoKVGxnZ1EyOXVkSEp2Ykd4bGNpQkJVRWtnVFdGdVlXZGxiV1Z1ZENJc0lBb2dJQ0FnSUNBZ0lDSnpaWEpwWVd3aU9pQTBNRE00TENBSwpJQ0FnSUNBZ0lDQWljM1ZpYzJOeWFYQjBhVzl1SWpvZ0lsUXdNREF4TWpBMk5qVWlMQ0FLSUNBZ0lDQWdJQ0FpZEhsd1pTSTZJQ0owCmNtbGhiQ0lzSUFvZ0lDQWdJQ0FnSUNKMlpYSnphVzl1SWpvZ01Rb2dJQ0FnZlFwZAoKLS0tLS0tQjI5QTlCNzA0NUEyMTg1Q0M4ODgyQzMzMTUyMUNGNTEKQ29udGVudC1UeXBlOiBhcHBsaWNhdGlvbi94LXBrY3M3LXNpZ25hdHVyZTsgbmFtZT0ic21pbWUucDdzIgpDb250ZW50LVRyYW5zZmVyLUVuY29kaW5nOiBiYXNlNjQKQ29udGVudC1EaXNwb3NpdGlvbjogYXR0YWNobWVudDsgZmlsZW5hbWU9InNtaW1lLnA3cyIKCk1JSUZ2QVlKS29aSWh2Y05BUWNDb0lJRnJUQ0NCYWtDQVFFeER6QU5CZ2xnaGtnQlpRTUVBZ0VGQURBTEJna3EKaGtpRzl3MEJCd0dnZ2dNek1JSURMekNDQWhlZ0F3SUJBZ0lKQUlNenBYUUhwU3lhTUEwR0NTcUdTSWIzRFFFQgpDd1VBTUM0eEVqQVFCZ05WQkFvTUNVNUhTVTVZSUVsdVl6RVlNQllHQTFVRUF3d1BRMjl1ZEhKdmJHeGxjaUJEClFTQXhNQjRYRFRFNE1EVXhNVEV5TVRNMU1Wb1hEVEl5TURVeE1ERXlNVE0xTVZvd0xqRVNNQkFHQTFVRUNnd0oKVGtkSlRsZ2dTVzVqTVJnd0ZnWURWUVFEREE5RGIyNTBjbTlzYkdWeUlFTkJJREV3Z2dFaU1BMEdDU3FHU0liMwpEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURSVmNSRzFuV0tUMk8vc3JyNllmc01nN0VDeXBHaHJoM3JEc0ZkCkV1cEs1UWRRN01SLzNIa2I5NERZOHg5TGNJZDVVY2ZxVzFaWXVzeGdaRk5seDlvcG1ZZmluZmlzV2hxcmV1WUoKTWpwVU82SC81Ly9ZUTZObFdOS0FHQzJqejZMbEdEK1cwMmpBUzNkR1BjM0V5Ti9hZzd5VXNYSm1KZXZFVCt1MApxbFFyNEFwWWp2Z1dTdjRtaVdCY2pmMW0xM3M1RlQwYXVsKzFFSXpIUVhLaitsYUdMSE1Lc2FGdDFHaC9xMHlaCmhLTXlyaXBZTERqR1FlTVFvc3g1bGFBQWdKN04zTG54UW56UmlBNkN0OUJGYm9wLzBGN1Q2djY0QXFCUEduNEIKbXpvbEN2ZXNZZ2lrK2p1Q0RsTU9GTWxVeHJxU3oxQXZRZVBzOGdZcW9hQXJ0U2NUQWdNQkFBR2pVREJPTUIwRwpBMVVkRGdRV0JCUVNhV0dtV3FzbU1zc3hXcCtYamx6a3d5bjhYVEFmQmdOVkhTTUVHREFXZ0JRU2FXR21XcXNtCk1zc3hXcCtYamx6a3d5bjhYVEFNQmdOVkhSTUVCVEFEQVFIL01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ3AKN3phRDFOdk0xRFRFUHprQ05vOEIwbVA4ZDE0S3VleWFZcFYvbXdNS2tBa3NsTHZwdzE5ai85d1p4OEZtMlpGTgpUTkJUUmIvbXBIdGZOUENQSlkxM2NtZVFKNkdQTUE1eGxnL0lMd0lic083bEp6NGxGbFhZYU1qaCsrR3ZFTy9rClhFbC9OVUZ0TnFtcmI0c3pYSjJTaGJyMkoxaDB6VEZuazJ3MVgzcFZwaWsyVk5qSmY3dVQ2dDVUTlpXcERIRnQKS1c0YWZJeHdFNXVzVXFLOERBd2JyS2sxRkIreEtNV05wVEtYMXlzNk4rRmZlVXljNkh1WjNKRlczQjZYTTMrOQpMOXJlSmxpMlRRa2JvaUJNUElxS2RSRlRaL2xkYTR0d01uaURFRjlZZE03ekJ0elZmeFRpZjdReWJ3aWd3L1AxCmhUSUZRaWkzUElqS3ZDcmR3RkJmTVlJQ1RUQ0NBa2tDQVFFd096QXVNUkl3RUFZRFZRUUtEQWxPUjBsT1dDQkoKYm1NeEdEQVdCZ05WQkFNTUQwTnZiblJ5YjJ4c1pYSWdRMEVnTVFJSkFJTXpwWFFIcFN5YU1BMEdDV0NHU0FGbApBd1FDQVFVQW9JSGtNQmdHQ1NxR1NJYjNEUUVKQXpFTEJna3Foa2lHOXcwQkJ3RXdIQVlKS29aSWh2Y05BUWtGCk1ROFhEVEl5TURNd016QTNNalF3TTFvd0x3WUpLb1pJaHZjTkFRa0VNU0lFSU5GbUVQc1VJRzg3Z1ZJSXJCZFYKN24yNDRnQ1FJVjA0RWJESXB1Z2QybGNZTUhrR0NTcUdTSWIzRFFFSkR6RnNNR293Q3dZSllJWklBV1VEQkFFcQpNQXNHQ1dDR1NBRmxBd1FCRmpBTEJnbGdoa2dCWlFNRUFRSXdDZ1lJS29aSWh2Y05Bd2N3RGdZSUtvWklodmNOCkF3SUNBZ0NBTUEwR0NDcUdTSWIzRFFNQ0FnRkFNQWNHQlNzT0F3SUhNQTBHQ0NxR1NJYjNEUU1DQWdFb01BMEcKQ1NxR1NJYjNEUUVCQVFVQUJJSUJBRStJY1lYeW90Sld1VmFEK0p5Y00xU2pqdkhJTm9idVJWTVU1TllVQ1JVWAp4ZHFreTBUc1pIVnJocGZXYVU5d2RFakgvNEsxY1VHTW9SN3FXcEZmZWVlR0FZNlVicnRNRnZka293Q0NTN1VnCk9wbVhhdjhSZHR2STB5YjFqb09HbnZyMTYxNER6NTdQL1licHZ6WmdWQ3FsZHgrdUV4YXpWRU9nbzFiUHR6QVAKbTFkb1dWSjJqRStJV25pd245dE1mRG1VeWlGZ1N2bmNvM3E5V1QwUGNURUc4bXpmdkFWRGp6MmpaaVU1Z0hGbQpMVkFhRUt1SHY3RnR1aExHd1ExQmdzbjZ4NkpyTldGNXdRQVNvdU9iVGxvczE4U0lVTVFseVE5UThmNzNwdlgvCmNJSnRSZkVJRFpNR1RoY0VMalY1VTErN0g0bjB6ZDhPVXZSTVc5TG5QS0U9CgotLS0tLS1CMjlBOUI3MDQ1QTIxODVDQzg4ODJDMzMxNTIxQ0Y1MS0tCgo="}'
    EOF
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
