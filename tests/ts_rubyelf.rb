# -*- coding: utf-8 -*-
# Copyright © 2007-2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'test/unit/ui/console/testrunner'
require 'test/unit/testsuite'
require 'pathname'

require Pathname.new(__FILE__).dirname + 'tt_elf'

require Pathname.new(__FILE__).dirname + 'tc_bytestream'
require Pathname.new(__FILE__).dirname + 'tc_dynamic_executable'
require Pathname.new(__FILE__).dirname + 'tc_static_executable'
require Pathname.new(__FILE__).dirname + 'tc_relocatable'
require Pathname.new(__FILE__).dirname + 'tc_exceptions'
require Pathname.new(__FILE__).dirname + 'tc_arm'
require Pathname.new(__FILE__).dirname + 'tc_sunw_sections'
require Pathname.new(__FILE__).dirname + 'tc_versioning'
require Pathname.new(__FILE__).dirname + 'tc_solaris_versioning'
require Pathname.new(__FILE__).dirname + 'tc_nmcodes'
require Pathname.new(__FILE__).dirname + 'tc_symboltable'
require Pathname.new(__FILE__).dirname + 'tc_stringtable'

class TS_RubyElf
  def self.suite
    suite = Test::Unit::TestSuite.new("Ruby-Elf testsuite")
    suite << TC_Bytestream.suite
    suite << TC_Exceptions.suite
    suite << TC_ARM.suite
    suite << TC_SunW_Sections.suite
    suite << TC_Versioning.suite
    suite << TC_Solaris_Versioning.suite
    suite << TC_SymbolTable.suite
    suite << TC_StringTable.suite
  end
end

[TS_RubyElf,
 TC_Dynamic_Executable.subsuite,
 TC_Static_Executable.subsuite,
 TC_Relocatable.subsuite,
 TC_NM_Codes.subsuite].each do |suite|
  Test::Unit::UI::Console::TestRunner.run(suite)
end
