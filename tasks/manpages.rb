# -*- coding: utf-8 -*-
#
# Rakefile tasks for Ruby-Elf
# Copyright © 2011 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this generator; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

XSL_NS_ROOT="http://docbook.sourceforge.net/release/xsl-ns/current"

rule '.1' => [ '.1.xml' ] + FileList["manpages/*.xmli"] do |t|
  sh "xsltproc", "--stringparam", "man.copyright.section.enabled", "0", \
  "--xinclude", "-o", t.name, "#{XSL_NS_ROOT}/manpages/docbook.xsl", \
  t.source
end

ManpagesList = FileList["manpages/*.1.xml"].collect { |file|
  file.sub(/\.1\.xml$/, ".1")
}

desc "Build the man pages for the installed tools"
task :manpages => ManpagesList

desc "Remove manpages products"
task :clobber_manpages do
  FileList["manpages/*.1"].each do |file|
    File.unlink(file)
  end
end

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
