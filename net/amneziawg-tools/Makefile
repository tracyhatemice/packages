#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=amneziawg-tools
PKG_VERSION:=1.0.20260618
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/amnezia-vpn/amneziawg-tools.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)-2
PKG_MIRROR_HASH:=583ad89bdf30318c8cab6c7176ec058f0317914c85c10f049dd9df1874921676

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING
PKG_MAINTAINER:=tracyhatemice <tracyhatemice@users.noreply.github.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

MAKE_PATH:=src
MAKE_VARS += PLATFORM=linux

define Package/amneziawg-tools
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  URL:=https://amnezia.org/
  TITLE:=AmneziaWG userspace control program (awg)
  DEPENDS:= \
	  +@BUSYBOX_CONFIG_IP \
	  +@BUSYBOX_CONFIG_FEATURE_IP_LINK \
	  +kmod-amneziawg
endef

define Package/amneziawg-tools/description
  AmneziaWG is a fork of WireGuard that adds traffic obfuscation, making its
  handshakes and packet sizes harder to fingerprint by deep packet inspection
  while keeping WireGuard's cryptography and performance.

  This package provides the userspace control program for AmneziaWG, `awg`, a
  netifd protocol handler, and a re-resolve watchdog script.
endef

define Package/amneziawg-tools/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/wg $(1)/usr/bin/awg
	$(INSTALL_BIN) ./files/amneziawg_watchdog $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/lib/netifd/proto/
	$(INSTALL_DATA) ./files/amneziawg.uc $(1)/lib/netifd/proto/
endef

$(eval $(call BuildPackage,amneziawg-tools))
