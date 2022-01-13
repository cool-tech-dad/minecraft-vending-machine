#########################################################
### Defines Azure Resource Manager Terraform Provider ###
#########################################################
provider "azurerm" {
    version = "2.9.0"
    features {}
}
#########################################################
######### Creates Azure Resource Group ##################
#########################################################
resource "azurerm_resource_group" "useast-minecraftaci-rg" {
  name = var.resource_group_name
  location = var.resource_location
}

#########################################################
######### Creates Azure Storage Account #################
#########################################################

resource "azurerm_storage_account" "useast-aci-storage" {
  name = "useastacistorage"
  resource_group_name = azurerm_resource_group.useast-minecraftaci-rg.name
  location = azurerm_resource_group.useast-minecraftaci-rg.location
  account_tier = "Premium"
  account_replication_type = "LRS"
  account_kind = "FileStorage"

}

#########################################################
######### Creates 100GB Azure File Share#################
#########################################################
resource "azurerm_storage_share" "useast-aci-share" {
  name = "acishare"
  storage_account_name = azurerm_storage_account.useast-aci-storage.name
  quota = 100
}

#########################################################
######### Creates Azure Container Instance Group ########
########## 1 Minecraft Container is Created #############
########### 1 CPU and 2 GB Memory Allocated #############
#########################################################
resource "azurerm_container_group" "useast-minecraftaci-cg" {
  name = "useast-minecraft-aci"
  location = azurerm_resource_group.useast-minecraftaci-rg.location
  resource_group_name = azurerm_resource_group.useast-minecraftaci-rg.name
  ip_address_type = "public"
  dns_name_label = "tedstestaci"
  os_type = "Linux"
  
  container {
    name = "minecraft"
    image = "docker.io/cooltechdad/minecraft-bds:0.5"
    cpu = "1"
    memory = "2"

    ports {
      port = "19132"
      protocol = "UDP"
    }

    environment_variables = {
      "debug" = "true",
      "bds_version" = "1.18.2.03",
      "eula" = "TRUE",
      "level_name" = "Bedrock level",
      "gamemode" = "creative",
      "difficulty" = "normal",
      "allow_cheats" = "false",
      "max_players" = "1000",
      "server_authoritative_movement" = "server-auth-with-rewind"
    }

    volume {
      name = "pv001"
      mount_path = "/data"
      storage_account_name = azurerm_storage_account.useast-aci-storage.name
      storage_account_key = azurerm_storage_account.useast-aci-storage.primary_access_key
      share_name = azurerm_storage_share.useast-aci-share.name
    }
  }
  
  depends_on = [
    azurerm_storage_account.useast-aci-storage,
    azurerm_storage_share.useast-aci-share
  ]
}
#########################################################
########### Creates some useful outputs #################
###### this provides ease of use for connectivity #######
#########################################################
output "container_ip_address" {
  value = azurerm_container_group.useast-minecraftaci-cg.ip_address
}
