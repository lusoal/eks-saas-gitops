locals {}

# It will deploy the infraestructure for all the apps
module "siloed_tenant_tenant-2" {
  source = "../../../modules/tenant-apps"
  bucket_name = "tenant-2"
}