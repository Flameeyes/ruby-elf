MANPAGES = $(patsubst %.xml,%,$(wildcard manpages/*.xml))

all: manpages

manpages: $(MANPAGES)

XSL_NS_ROOT=http://docbook.sourceforge.net/release/xsl-ns/current

%: %.xml
	xsltproc -o $@ $(XSL_NS_ROOT)/manpages/docbook.xsl $<

clean:
	-rm $(MANPAGES)

RUBY = ruby
RCOV = rcov --comments

test check:
	$(RUBY) -I lib tests/ts_rubyelf.rb

cov:
	$(RCOV) -I lib tests/ts_rubyelf.rb lib/elf.rb lib/elf/*.rb

cov-harsh:
	$(MAKE) RCOV="$(RCOV) --test-unit-only" cov
