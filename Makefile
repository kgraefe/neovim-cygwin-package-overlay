PKGS=\
	 luajit \
	 luajit-lpeg \
	 luajit-mpack \
	 msgpack-c \
	 libluv \
	 unibilium \
	 libtermkey \
	 libvterm \
	 neovim \

GREEN="$(shell tput setaf 2)"
NORMAL="\\e[0m"

-include local.mak

ifneq ($(V),1)
	Q:=@
endif

build: clean
	mkdir -p x86_64/release

	$(Q)@for PKT in $(PKGS); do \
		printf "$(GREEN)=== Download $$PKT ===$(NORMAL)\n"; \
		URL=$$( \
			curl https://api.github.com/repos/kgraefe/$$PKT-cygwin/releases/latest \
			| jq -r '.assets[] | select(.name | test("-dist-")).browser_download_url' \
		); \
		test -z "$$URL" && exit 1; \
		curl -L "$$URL" | tar -C x86_64/release/ -xJv ; \
	done

	$(Q)@printf "$(GREEN)=== Generate setup.ini files ===$(NORMAL)\n"
	mksetupini \
		--arch x86_64 \
		--inifile=x86_64/setup.ini \
		--release=cygwin.paktolos.net \
		--releasearea=. \
		--disable-check=missing-required-package,missing-depended-package
	gpg --local-user 565EA3DDF4DF90C056894467D299701EAA73A441 --detach-sign x86_64/setup.ini
	bzip2 < x86_64/setup.ini > x86_64/setup.bz2
	gpg --local-user 565EA3DDF4DF90C056894467D299701EAA73A441 --detach-sign x86_64/setup.bz2
	xz -6e < x86_64/setup.ini > x86_64/setup.xz
	gpg --local-user 565EA3DDF4DF90C056894467D299701EAA73A441 --detach-sign x86_64/setup.xz

upload: build
	$(Q)@printf "$(GREEN)=== Upload all the things ===$(NORMAL)\n"
	rsync -avz --progress --omit-dir-times \
		index.html x86_64 \
		www-data@paktolos:/var/www/paktolos.net/cygwin/ \
		--delete

clean:
	$(Q)@printf "$(GREEN)=== Clean all the things ===$(NORMAL)\n"
	rm -rf x86_64
