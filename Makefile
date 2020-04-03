PREFIX ?= /usr/local
DEST ?= /

.PHONY: all install uninstall clean

all:
	@echo "you can just make install"

clean:
	@echo "successfully done nothing"

install:
	install -m 0755 ansible-pull-verify.sh $(DEST)/$(PREFIX)/
uninstall:
	rm -f $(DEST)/$(PREFIX)/ansible-pull-verify.sh

