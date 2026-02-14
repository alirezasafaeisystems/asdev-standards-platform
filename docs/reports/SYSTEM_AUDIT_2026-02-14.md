# System Audit (2026-02-14)

## Hardware
- CPU: Intel Core i5-10400 (6C/12T), max 4.3GHz
- RAM: 24GB (23GiB usable)
- GPU: AMD Radeon RX 580 8GB (Polaris10)
- System disk: 120GB SSD (`/dev/sdc2`, ext4, `/`)
- Additional storage: 240GB SSD + 6TB HDD

## OS / Kernel
- OS: Ubuntu 24.04.3 LTS
- Kernel: 6.17.0-14-generic

## GPU/Compute Stack
- amdgpu kernel module: loaded
- Vulkan: RADV available (`vulkaninfo` OK)
- OpenCL: enabled via Mesa (`clinfo` OK)
  - Detected GPU device: `AMD Radeon RX 580 Series`

## Dev Runtime Stack
- Node.js: v24.13.0
- npm: 11.6.2
- pnpm: 10.28.2
- bun: 1.3.9
- Python: 3.12.3
- Java: OpenJDK 21.0.10

## Performance Tuning Applied
- CPU governor: `performance` on all 12 logical CPUs
- vm.swappiness: `10`
- vm.vfs_cache_pressure: `50`
- Persistent service: `/etc/systemd/system/asdev-performance-tuning.service`
- Persistent sysctl: `/etc/sysctl.d/99-asdev-performance.conf`

## Autonomous Execution
- Service: `asdev-autonomous-executor.service` (enabled/active)
- Execution profile: `max`
- Max parallel jobs: `12`
- Node old-space: `12288 MB`
- UV threadpool: `48`
- Pipeline runner: `run-priority-pipelines-max.sh`
