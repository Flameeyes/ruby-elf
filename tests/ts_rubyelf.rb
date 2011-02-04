# -*- coding: utf-8 -*-
# Copyright © 2007-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# Avoid repeating the same call over and over
def require_testfile(file)
  require File.expand_path("../#{file}", __FILE__)
end

require_testfile 'tt_elf'

require_testfile 'tc_bytestream'
require_testfile 'tc_dynamic_executable'
require_testfile 'tc_static_executable'
require_testfile 'tc_relocatable'
require_testfile 'tc_exceptions'
require_testfile 'tc_arm'
require_testfile 'tc_sunw_sections'
require_testfile 'tc_versioning'
require_testfile 'tc_solaris_versioning'
require_testfile 'tc_nmcodes'
require_testfile 'tc_symboltable'
require_testfile 'tc_stringtable'
require_testfile 'tc_symbols_comparison'
require_testfile 'tc_values'
require_testfile 'tc_demangler'
require_testfile 'tc_shared_object'

class TS_RubyElf
  def self.suite
    suite = Test::Unit::TestSuite.new("Ruby-Elf testsuite")
    suite << TC_Bytestream.suite
    suite << TC_Exceptions.suite
    suite << TC_ARM.suite
    suite << TC_SunW_Sections.suite
    suite << TC_Solaris_Versioning.suite
    suite << TC_SymbolTable.suite
    suite << TC_StringTable.suite
    suite << TC_Symbols_Comparison.suite
    suite << TC_Values.suite
    # this is just a bunch of assertions in one or two tests so don't
    # make it its own suite, if at all possible.
    suite << Elf::TestDemangler.subsuite
  end
end

# The verbose parameter is different between the Test::Unit shipped
# with Ruby 1.8 and the one provided by test-unit 2.x gem.
begin
  verbose = (ENV['TEST_VERBOSE'] == '1') ? Test::Unit::UI::VERBOSE : Test::Unit::UI::NORMAL
rescue NameError
  verbose = { :output_level =>
    (ENV['TEST_VERBOSE'] == '1') ? Test::Unit::UI::Console::OutputLevel::VERBOSE : Test::Unit::UI::Console::OutputLevel::NORMAL
  }
end

[TS_RubyElf,
 Elf::TestDynamicExecutable.subsuite,
 Elf::TestStaticExecutable.subsuite,
 Elf::TestRelocatable.subsuite,
 Elf::TestNMCodes.subsuite,
 Elf::TestVersioning.subsuite,
 Elf::TestSharedObject.subsuite,
].each do |suite|
  
  Test::Unit::UI::Console::TestRunner.run(suite, verbose)
end
