include Makefile.config

buildroot := _build

ensure_config_var_set = @$(if $($(1)),:,echo Must set $(1) in Makefile.config; false)

manifest_command_gpg_args = $(if $(arg_release),--gpg-homedir=gpg --gpg-sign=$(RELEASE_GPG_KEY),)
manifest_command_repo = $(if $(arg_release),release-repo,repo)

all: test

remote-add:
	flatpak remote-add --user firefox $(PWD)/repo --no-gpg-verify

_manifest:
	@$(if $(arg_manifest),:,echo make _manifest is an internal command; false)
	@mkdir -p $(buildroot)
	flatpak-builder --force-clean --repo=$(manifest_command_repo) --ccache $(manifest_command_gpg_args) $(buildroot)/$(basename $(arg_manifest)) $(arg_manifest)
	flatpak build-update-repo $(manifest_command_repo) $(if $(arg_release),--generate-static-deltas) $(manifest_command_gpg_args)

test: org.mozilla.Firefox.yaml | repo
	$(MAKE) _manifest arg_repo=repo arg_manifest=$<

release: org.mozilla.Firefox.yaml | release-repo
	$(call ensure_config_var_set,RELEASE_GPG_KEY)
	$(MAKE) _manifest arg_manifest=$< arg_release=1

test-plugin-%: plugins/org.mozilla.Firefox.Plugin.%.yaml
	$(MAKE) _manifest arg_manifest=$<

release-plugin-%: plugins/org.mozilla.Firefox.Plugin.%.yaml
	$(MAKE) _manifest arg_manifest=$< arg_release=1

test-plugins: test-plugin-Flash

release-plugins: release-plugin-Flash

clean:
	rm -rf $(app)/*

repo:
	ostree init --mode=archive-z2 --repo=repo

release-repo:
	ostree init --mode=archive-z2 --repo=release-repo

gpg-key:
	$(call ensure_config_var_set,KEY_USER)
	mkdir -p gpg
	gpg2 --homedir gpg --quick-gen-key ${KEY_USER}
	@echo Enter the above gpg key id as RELEASE_GPG_KEY in Makefile.config

$(app).flatpakref: $(app).flatpakref.in
	sed -e "s|@URL@|$(URL)g;s|@GPG@|$$(gpg2 --homedir=gpg --export $(RELEASE_GPG_KEY) | base64 | tr -d '\n')|g" $< > $@
