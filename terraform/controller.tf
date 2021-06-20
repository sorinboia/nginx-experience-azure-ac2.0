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
  vm_size               = "Standard_D4_v2"

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
      apt-get install socat ebtables conntrack install jq -y   
      wget https://sorinnginx.s3.eu-central-1.amazonaws.com/controller-installer-3.15-6.0.tar.gz -O /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      export HOME=/home/ubuntu
      #/home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email admin@nginx.com --admin-password Admin2021 --self-signed-cert --auto-install-docker --configdb-volume-type local --tsdb-volume-type local
      runuser -l ubuntu -c 'host_ip=$(curl -s ifconfig.me) && /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email admin@nginx.com --admin-password Admin2021 --self-signed-cert --auto-install-docker --configdb-volume-type local --tsdb-volume-type local'
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "admin@nginx.com","password": "Admin2021"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLTAwM0QwNUU3NTc1NkQyOTlDMTA1RjA0MDc2QkU0Q0VFIgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLTAwM0QwNUU3NTc1NkQyOTlDMTA1RjA0MDc2QkU0Q0VFCld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNUzB3TmkweE1WUXdOam95TXpvek1DNDFPVGMyTmpOYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURNME9UTXNJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpVkRBd01ERXhNRFF4T1NJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0luUnlhV0ZzSWl3Z0NpQWcKSUNBZ0lDQWdJblpsY25OcGIyNGlPaUF4Q2lBZ0lDQjlMQ0FLSUNBZ0lIc0tJQ0FnSUNBZ0lDQWlaWGh3YVhKNUlqb2dJakl3TWpFdApNRFl0TVRGVU1EWTZNak02TXpBdU5UazNNelF3V2lJc0lBb2dJQ0FnSUNBZ0lDSnNhVzFwZEhNaU9pQTVPVGs1T1N3Z0NpQWdJQ0FnCklDQWdJbXhwYldsMGMxOWhjR2xmWTJGc2JITWlPaUF4TURBd01EQXdNREF3TENBS0lDQWdJQ0FnSUNBaWNISnZaSFZqZENJNklDSk8KUjBsT1dDQkRiMjUwY205c2JHVnlJRUZRU1NCTllXNWhaMlZ0Wlc1MElpd2dDaUFnSUNBZ0lDQWdJbk5sY21saGJDSTZJRE0wT1RNcwpJQW9nSUNBZ0lDQWdJQ0p6ZFdKelkzSnBjSFJwYjI0aU9pQWlWREF3TURFeE1EUXhPU0lzSUFvZ0lDQWdJQ0FnSUNKMGVYQmxJam9nCkluUnlhV0ZzSWl3Z0NpQWdJQ0FnSUNBZ0luWmxjbk5wYjI0aU9pQXhDaUFnSUNCOUNsMD0KCi0tLS0tLTAwM0QwNUU3NTc1NkQyOTlDMTA1RjA0MDc2QkU0Q0VFCkNvbnRlbnQtVHlwZTogYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmU7IG5hbWU9InNtaW1lLnA3cyIKQ29udGVudC1UcmFuc2Zlci1FbmNvZGluZzogYmFzZTY0CkNvbnRlbnQtRGlzcG9zaXRpb246IGF0dGFjaG1lbnQ7IGZpbGVuYW1lPSJzbWltZS5wN3MiCgpNSUlGdkFZSktvWklodmNOQVFjQ29JSUZyVENDQmFrQ0FRRXhEekFOQmdsZ2hrZ0JaUU1FQWdFRkFEQUxCZ2txCmhraUc5dzBCQndHZ2dnTXpNSUlETHpDQ0FoZWdBd0lCQWdJSkFJTXpwWFFIcFN5YU1BMEdDU3FHU0liM0RRRUIKQ3dVQU1DNHhFakFRQmdOVkJBb01DVTVIU1U1WUlFbHVZekVZTUJZR0ExVUVBd3dQUTI5dWRISnZiR3hsY2lCRApRU0F4TUI0WERURTRNRFV4TVRFeU1UTTFNVm9YRFRJeU1EVXhNREV5TVRNMU1Wb3dMakVTTUJBR0ExVUVDZ3dKClRrZEpUbGdnU1c1ak1SZ3dGZ1lEVlFRRERBOURiMjUwY205c2JHVnlJRU5CSURFd2dnRWlNQTBHQ1NxR1NJYjMKRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEUlZjUkcxbldLVDJPL3NycjZZZnNNZzdFQ3lwR2hyaDNyRHNGZApFdXBLNVFkUTdNUi8zSGtiOTREWTh4OUxjSWQ1VWNmcVcxWll1c3hnWkZObHg5b3BtWWZpbmZpc1docXJldVlKCk1qcFVPNkgvNS8vWVE2TmxXTktBR0Myano2TGxHRCtXMDJqQVMzZEdQYzNFeU4vYWc3eVVzWEptSmV2RVQrdTAKcWxRcjRBcFlqdmdXU3Y0bWlXQmNqZjFtMTNzNUZUMGF1bCsxRUl6SFFYS2orbGFHTEhNS3NhRnQxR2gvcTB5WgpoS015cmlwWUxEakdRZU1Rb3N4NWxhQUFnSjdOM0xueFFuelJpQTZDdDlCRmJvcC8wRjdUNnY2NEFxQlBHbjRCCm16b2xDdmVzWWdpaytqdUNEbE1PRk1sVXhycVN6MUF2UWVQczhnWXFvYUFydFNjVEFnTUJBQUdqVURCT01CMEcKQTFVZERnUVdCQlFTYVdHbVdxc21Nc3N4V3ArWGpsemt3eW44WFRBZkJnTlZIU01FR0RBV2dCUVNhV0dtV3FzbQpNc3N4V3ArWGpsemt3eW44WFRBTUJnTlZIUk1FQlRBREFRSC9NQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUNwCjd6YUQxTnZNMURURVB6a0NObzhCMG1QOGQxNEt1ZXlhWXBWL213TUtrQWtzbEx2cHcxOWovOXdaeDhGbTJaRk4KVE5CVFJiL21wSHRmTlBDUEpZMTNjbWVRSjZHUE1BNXhsZy9JTHdJYnNPN2xKejRsRmxYWWFNamgrK0d2RU8vawpYRWwvTlVGdE5xbXJiNHN6WEoyU2hicjJKMWgwelRGbmsydzFYM3BWcGlrMlZOakpmN3VUNnQ1VE5aV3BESEZ0CktXNGFmSXh3RTV1c1VxSzhEQXdicktrMUZCK3hLTVdOcFRLWDF5czZOK0ZmZVV5YzZIdVozSkZXM0I2WE0zKzkKTDlyZUpsaTJUUWtib2lCTVBJcUtkUkZUWi9sZGE0dHdNbmlERUY5WWRNN3pCdHpWZnhUaWY3UXlid2lndy9QMQpoVElGUWlpM1BJakt2Q3Jkd0ZCZk1ZSUNUVENDQWtrQ0FRRXdPekF1TVJJd0VBWURWUVFLREFsT1IwbE9XQ0JKCmJtTXhHREFXQmdOVkJBTU1EME52Ym5SeWIyeHNaWElnUTBFZ01RSUpBSU16cFhRSHBTeWFNQTBHQ1dDR1NBRmwKQXdRQ0FRVUFvSUhrTUJnR0NTcUdTSWIzRFFFSkF6RUxCZ2txaGtpRzl3MEJCd0V3SEFZSktvWklodmNOQVFrRgpNUThYRFRJeE1EVXhNakEyTWpNek1Gb3dMd1lKS29aSWh2Y05BUWtFTVNJRUlMZ1VRMHhCM2pQMzdWUHRiWnFBCjd0UndBNm5VSWlOVWphMnZSN3lVNUloTE1Ia0dDU3FHU0liM0RRRUpEekZzTUdvd0N3WUpZSVpJQVdVREJBRXEKTUFzR0NXQ0dTQUZsQXdRQkZqQUxCZ2xnaGtnQlpRTUVBUUl3Q2dZSUtvWklodmNOQXdjd0RnWUlLb1pJaHZjTgpBd0lDQWdDQU1BMEdDQ3FHU0liM0RRTUNBZ0ZBTUFjR0JTc09Bd0lITUEwR0NDcUdTSWIzRFFNQ0FnRW9NQTBHCkNTcUdTSWIzRFFFQkFRVUFCSUlCQUovTk9pcDdMZDJ0Y2xZcHl5MDE4TFN2amR0MXYrRk5sVkUyaksxcEY4eFQKMU9wV1FieDEvZ3VWLzRPR3F4RmYvYWd6VnpoVmhiZEhMRk1Rb200alhRLyt5aDZGRDdYcEo5b1VuVVAzbi9sSApxZ0UyWm8xZll0M05Wa3pZVE8veEE3TVdBeSt1UFlvdFdBSXpiWm5tNUx4M2FUME5Jb1JTeDFITzlvaHRVOFZuCi84K0JzdUEzbmR6LzdiUmk3bUN1bGttWVJKSlRGK0lsb0JMVUhLaDBRcUlZSDhqU2c2Z0liRFdhWU0zclpGR1YKYVE0ZVRwYkgzN0c4THg3WjV1RDJvK0sxbnlVaTZadC94cDBBYjZZSnFaTW0wY2NFZC8xWFowM05oRGRxcjBqegp6WnZVck1nWTdvYWJpTjdFbExTMWhBU2R5ZVJzbXpOeFpRMFZ3V3IvWkI0PQoKLS0tLS0tMDAzRDA1RTc1NzU2RDI5OUMxMDVGMDQwNzZCRTRDRUUtLQoK"}'
    EOF
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}