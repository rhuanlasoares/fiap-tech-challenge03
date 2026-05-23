output "redis_private_ip" {
  value = google_redis_instance.instance.host
}
