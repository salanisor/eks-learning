output "chart_version" {
  description = "Installed ESO chart version"
  value       = helm_release.external_secrets.version
}