install:
	mkdir -p $(DESTDIR)/usr/bin || true
	mkdir -p $(DESTDIR)/usr/lib/elsa || true
	cp -prfv *.sh $(DESTDIR)/usr/lib/elsa/
	install elsa $(DESTDIR)/usr/bin/elsa
