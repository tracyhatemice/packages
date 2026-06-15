# SPDX-License-Identifier: MIT
#
# Copyright (c) 2017 Yu Wang <wangyucn@gmail.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=udp2raw
PKG_VERSION:=20251012.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/wangyu-/udp2raw
PKG_SOURCE_DATE:=2025-10-12
PKG_SOURCE_VERSION:=4208db6e27c46f3ccec8b98722af7ec23bc62e73
PKG_MIRROR_HASH:=ca3eb8b5e7309883a6a379f023d0eb365c6d51e968b67e611ad01f990cc62dc2

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Yu Wang

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/udp2raw
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Tunnel which turns UDP Traffic into Encrypted FakeTCP/UDP/ICMP Traffic
  URL:=https://github.com/wangyu-/udp2raw
  DEPENDS:=+libstdcpp +libpthread +librt
  PROVIDES:=udp2raw-tunnel
endef

define Package/udp2raw/description
  udp2raw-tunnel is a tunnel which turns UDP Traffic into Encrypted FakeTCP/UDP/ICMP Traffic by using Raw Socket.
endef

MAKE_FLAGS += cross

define Build/Prepare
	$(PKG_UNPACK)
	sed -i 's/cc_cross=.*/cc_cross=$(TARGET_CXX)/g' $(PKG_BUILD_DIR)/makefile
	sed -i '/\*gitversion/d' $(PKG_BUILD_DIR)/makefile
	echo 'const char *gitversion = "$(PKG_VERSION)";' > $(PKG_BUILD_DIR)/git_version.h
	$(Build/Patch)
endef

define Package/udp2raw/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/udp2raw_cross $(1)/usr/sbin/udp2raw
endef

$(eval $(call BuildPackage,udp2raw))
