MANPAGES = $(patsubst %.xml,%,$(wildcard manpages/*.xml))
DEMANGLERS = $(patsubst %.rl,%.rb,$(wildcard lib/elf/symbol/demangler_*.rl))

all: manpages-build $(DEMANGLERS)

manpages-build: $(MANPAGES)

XSL_NS_ROOT=http://docbook.sourceforge.net/release/xsl-ns/current

%: %.xml $(wildcard manpages/*.xmli)
	xsltproc --stringparam man.copyright.section.enabled 0 --xinclude -o $@ $(XSL_NS_ROOT)/manpages/docbook.xsl $<

%.rb: %.rl
	ragel -R $< -o $@

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
