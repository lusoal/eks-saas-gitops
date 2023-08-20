locals {}

# It will deploy only the infraestructure of the siloed services
module "hybrid_tenant_tenant-4" {
  source = "../../../modules/tenant-apps"
  bucket_name = "tenant-4"
  enable_consumer = false
}