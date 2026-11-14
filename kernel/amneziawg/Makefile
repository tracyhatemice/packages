#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=amneziawg
# Upstream tags this release v3.1.20261113-02. apk rejects a hyphen inside a
# version, so the package uses apk's patch-level suffix instead, which sorts
# above 3.1.20261113.
PKG_REALVERSION:=3.1.20261113-02
PKG_VERSION:=3.1.20261113_p2
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
PKG_SOURCE_VERSION:=v$(PKG_REALVERSION)
PKG_MIRROR_HASH:=d18a874643cd065945f0499176c738aec3c9b9e15720582611913210821fe861

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING
PKG_MAINTAINER:=tracyhatemice <tracyhatemice@users.noreply.github.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
MAKE_PATH:=src

include $(INCLUDE_DIR)/package.mk

define KernelPackage/amneziawg
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Support
  TITLE:=AmneziaWG VPN kernel module
  URL:=https://amnezia.org/
  FILES:=$(PKG_BUILD_DIR)/$(MAKE_PATH)/amneziawg.ko
  AUTOLOAD:=$(call AutoProbe,amneziawg)
  DEPENDS:= \
	  +kmod-udptunnel4 \
	  +kmod-udptunnel6 \
	  +kmod-crypto-lib-chacha20poly1305 \
	  +kmod-crypto-lib-curve25519
endef

define KernelPackage/amneziawg/description
  AmneziaWG is a fork of WireGuard that adds traffic obfuscation, making its
  handshakes and packet sizes harder to fingerprint by deep packet inspection
  while keeping WireGuard's cryptography and performance.

  This package provides the kernel module. The userspace control program is in
  the amneziawg-tools package.
endef

define Build/Compile
	$(MAKE_VARS) $(MAKE) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)/$(MAKE_PATH)" \
		EXTRA_CFLAGS="$(BUILDFLAGS)" \
		WIREGUARD_VERSION="$(WIREGUARD_VERSION)" \
		modules
endef

$(eval $(call KernelPackage,amneziawg))
