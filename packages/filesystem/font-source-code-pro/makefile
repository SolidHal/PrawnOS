all: font-source-code-pro-deb

.PHONY: font-source-code-pro-deb
font-source-code-pro-deb:
	cd src/; debuild -us -uc

.PHONY: clean
clean:
	rm -rf *.upload
	rm -rf *.deb
	rm -rf *.changes

.PHONY: upload
upload:
	dput deb.prawnos.com *.changes
