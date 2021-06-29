include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=longsung-cm
PKG_SOURCE_PROTO:=git
PKG_BRANCH:=master
PKG_RELEASE:=1


include $(INCLUDE_DIR)/package.mk


define Package/longsung-cm
	SECTION:=net
	CATEGORY:=Network
	TITLE:=longsung-cm 4G software
	DEPENDS:=
	URL:=https://
endef

define Package/longsung-cm/description
  longsung-cm 4G software
endef

define Build/Prepare
	cp -r src/. $(PKG_BUILD_DIR)
endef

#define Build/Configure
#endef

#define Build/Compile
#endef

define Build/Compile
	$(MAKE) -C "$(PKG_BUILD_DIR)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		SUBDIRS="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		CC="$(TARGET_CC)" \
		
endef

define Package/longsung-cm/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/longsung-cm.bin $(1)/usr/bin/longsung-cm
endef


$(eval $(call BuildPackage,longsung-cm))
