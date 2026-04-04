# Shared GPU configuration for crown and its containers.
# Keeps the NVIDIA driver package in sync between the host and GPU-passthrough containers
# to prevent driver/library version mismatches.
{
  driverPackage = "latest";
}
