resource "google_compute_global_address" "default" {
  project = var.project_id
  name    = "gke-ip-lb"
}

resource "google_compute_managed_ssl_certificate" "default" {
  project = var.project_id
  name    = "rhuan-managed-cert"
  managed {
    domains = [
      "rhuan-fiap.${google_compute_global_address.default.address}.nip.io",
      "grafana.${google_compute_global_address.default.address}.nip.io",
      "argocd.${google_compute_global_address.default.address}.nip.io"
    ]
  }
}
