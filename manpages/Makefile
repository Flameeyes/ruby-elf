all: cowstats.1

XSL_NS_ROOT=http://docbook.sourceforge.net/release/xsl-ns/current

%: %.xml
	xsltproc $(XSL_NS_ROOT)/manpages/docbook.xsl $<
