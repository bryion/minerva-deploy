Vagrant.configure("2") do |config|
  # Using Ubuntu 24.04 (Noble Numbat) for ARM64
  config.vm.box = "peru/ubuntu-24.04-arm64"

  config.vm.provider "qemu" do |qe|
    qe.arch = "aarch64"
    qe.machine = "virt"
    qe.cpu = "max"
    qe.net_device = "virtio-net-pci"
    # Allocate 2GB RAM and 2 CPUs for the test node
    qe.extra_qemu_args = %w(-m 2G -smp 2)
  end

  # Assign a static IP for the 'test' inventory group
  config.vm.network "private_network", ip: "192.168.64.50"

  config.vm.hostname = "minerva-test"

  # Sync your local files to the VM for testing
  config.vm.synced_folder ".", "/vagrant", disabled: true
end