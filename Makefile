PKGS=\
	 luajit-dist-2.1.0_beta3_20230221-3.x86_64.tar.xz

-include local.mak

define download_package
	$(eval PKG_FILENAME = $(notdir $@))
	$(eval PKG_NAME = $(firstword $(subst -dist-, ,$(PKG_FILENAME))))
	$(eval PKG_VERSION = $(patsubst $(PKG_NAME)-dist-%.x86_64.tar.xz,%,$(PKG_FILENAME)))
	mkdir -p $(dir $@)
	wget -P $(dir $@)/ "https://github.com/kgraefe/$(PKG_NAME)-cygwin/releases/download/$(PKG_VERSION)/$(PKG_FILENAME)"
endef

downloads/%.tar.xz:
	$(call download_package,$@)

build: $(addprefix downloads/,$(PKGS))
	rm -rf x86_64
	mkdir -p x86_64/release
	for pkg in $(PKGS); do \
		tar xJvf "downloads/$$pkg" -C x86_64/release/ ; \
	done
	mksetupini \
		--arch x86_64 \
		--inifile=x86_64/setup.ini \
		--releasearea=. \
		--disable-check=missing-required-package,missing-depended-package
	gpg --local-user 565EA3DDF4DF90C056894467D299701EAA73A441 --detach-sign x86_64/setup.ini
	bzip2 < x86_64/setup.ini > x86_64/setup.bz2
	gpg --local-user 565EA3DDF4DF90C056894467D299701EAA73A441 --detach-sign x86_64/setup.bz2
	xz -6e < x86_64/setup.ini > x86_64/setup.xz
	gpg --local-user 565EA3DDF4DF90C056894467D299701EAA73A441 --detach-sign x86_64/setup.xz

upload: build
	rsync -avz --progress --omit-dir-times \
		x86_64 \
		www-data@paktolos:/var/www/paktolos.net/cygwin/ \
		--delete

clean:
	rm -rf x86_64 downloads
