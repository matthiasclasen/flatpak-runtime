all: platform sdk

clean:
	rm -rf repo exportrepo .commit-*

PROXY=
VERSION=1
ARCH=x86_64

repo/config:
	ostree init --repo=repo --mode=bare-user

exportrepo/config:
	ostree init --repo=exportrepo --mode=archive-z2

repo/refs/heads/base/org.flatpak.Runtime/$(ARCH)/$(VERSION): repo/config flatpak-runtime.json treecompose-post.sh group passwd
	sudo rpm-ostree compose tree --force-nocache $(PROXY) --repo=repo flatpak-runtime.json
	sudo chown -R `whoami` repo

repo/refs/heads/base/org.flatpak.Sdk/$(ARCH)/$(VERSION): repo/config flatpak-sdk.json flatpak-runtime.json treecompose-post.sh group passwd
	sudo rpm-ostree compose tree --force-nocache $(PROXY) --repo=repo flatpak-sdk.json
	sudo chown -R `whoami` repo

repo/refs/heads/runtime/org.flatpak.Runtime/$(ARCH)/$(VERSION): repo/refs/heads/base/org.flatpak.Runtime/$(ARCH)/$(VERSION) metadata.runtime
	./commit-subtree.sh base/org.flatpak.Runtime/$(ARCH)/$(VERSION) runtime/org.flatpak.Runtime/$(ARCH)/$(VERSION) metadata.runtime /usr files

repo/refs/heads/runtime/org.flatpak.Runtime.Var/$(ARCH)/$(VERSION): repo/refs/heads/base/org.flatpak.Runtime/$(ARCH)/$(VERSION) metadata.runtime
	./commit-subtree.sh base/org.flatpak.Runtime/$(ARCH)/$(VERSION) runtime/org.flatpak.Runtime.Var/$(ARCH)/$(VERSION) metadata.runtime /var files /usr/share/rpm files/lib/rpm

repo/refs/heads/runtime/org.flatpak.Sdk/$(ARCH)/$(VERSION): repo/refs/heads/base/org.flatpak.Sdk/$(ARCH)/$(VERSION) metadata.sdk
	./commit-subtree.sh base/org.flatpak.Sdk/$(ARCH)/$(VERSION) runtime/org.flatpak.Sdk/$(ARCH)/$(VERSION) metadata.sdk /usr files

repo/refs/heads/runtime/org.flatpak.Sdk.Var/$(ARCH)/$(VERSION): repo/refs/heads/base/org.flatpak.Sdk/$(ARCH)/$(VERSION) metadata.sdk
	./commit-subtree.sh base/org.flatpak.Sdk/$(ARCH)/$(VERSION) runtime/org.flatpak.Sdk.Var/$(ARCH)/$(VERSION) metadata.sdk /var files /usr/share/rpm files/lib/rpm

exportrepo/refs/heads/runtime/org.flatpak.Runtime/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.flatpak.Runtime/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.flatpak.Runtime/$(ARCH)/$(VERSION)
	flatpak build-update-repo exportrepo

exportrepo/refs/heads/runtime/org.flatpak.Runtime.Var/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.flatpak.Runtime.Var/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.flatpak.Runtime.Var/$(ARCH)/$(VERSION)
	flatpak build-update-repo exportrepo

exportrepo/refs/heads/runtime/org.flatpak.Sdk/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.flatpak.Sdk/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.flatpak.Sdk/$(ARCH)/$(VERSION)
	flatpak build-update-repo exportrepo

exportrepo/refs/heads/runtime/org.flatpak.Sdk.Var/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.flatpak.Sdk.Var/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.flatpak.Sdk.Var/$(ARCH)/$(VERSION)
	flatpak build-update-repo exportrepo

platform: exportrepo/refs/heads/runtime/org.flatpak.Runtime/$(ARCH)/$(VERSION) exportrepo/refs/heads/runtime/org.flatpak.Runtime.Var/$(ARCH)/$(VERSION)

sdk: exportrepo/refs/heads/runtime/org.flatpak.Sdk/$(ARCH)/$(VERSION) exportrepo/refs/heads/runtime/org.flatpak.Sdk.Var/$(ARCH)/$(VERSION)

