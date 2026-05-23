# resource "google_vpc_access_connector" "vpc_connector" {
#   name           = "vpcac-rhuan"
#   project        = var.project_id
#   region         = var.region
#   ip_cidr_range  = "10.8.0.0/28" # var.environment_prefix == "dev" ? "10.8.0.0/28" : "10.8.0.0/28"
#   network        = google_compute_network.vpc_network.name
#   min_throughput = 200
#   max_throughput = 300
# }
