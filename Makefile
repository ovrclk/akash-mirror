SHELL   = /bin/sh
PREFIX  = /usr/local
SOURCES	= prelude.bash main.bash
PROGRAM = akash-mirror

execdir=$(PREFIX)/bin

default: $(PROGRAM)

$(PROGRAM): $(SOURCES)
	rm -rf $@
	cat $(SOURCES) > $@+
	bash -n $@+
	mv $@+ $@
	chmod 0755 $@

install: $(PROGRAM)
	install -d "$(execdir)"
	install -m 0755 $(PROGRAM) "$(execdir)/$(PROGRAM)"

all: $(PROGRAM) $(RUBIES) 
	./$(PROGRAM) --version

uninstall:
	rm -f "$(execdir)/$(PROGRAM)"

clean:
	rm -f $(PROGRAM)

.PHONY: $(PROGRAM) all install uninstall clean
