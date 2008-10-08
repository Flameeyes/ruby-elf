all: manpages

manpages: manpages/cowstats.1 manpages/missingstatic.1

XSL_NS_ROOT=http://docbook.sourceforge.net/release/xsl-ns/current

%: %.xml
	xsltproc $(XSL_NS_ROOT)/manpages/docbook.xsl $<

RUBY = ruby

test check:
	$(RUBY) -I lib tests/ts_rubyelf.rb
