# -*- coding: utf-8 -*-
# Copyright © 2008-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'test/unit'
require 'pathname'
require 'elf'
require File.dirname(__FILE__) + '/tt_elf' unless defined? Elf::BaseTest

# Test for demangler support
module Elf::TestDemangler
  include Elf::BaseTest

  BaseFilename = "cxxsymbols.o"

  def test_demangling
    self.class::MangledSymbols.each_pair do |mangled, demangled|
      assert_equal demangled, @elf[".symtab"][mangled].demangle
    end
  end

  class GCC3 < Test::Unit::TestCase
    include Elf::TestDemangler
    Os = "linux"
    Arch = "amd64"
    Compiler="gcc"

    MangledSymbols = {
      "_ZN11mynamespace12list_of_intsE" => "mynamespace::list_of_ints",
      "_ZN11mynamespace8functionEv" => "mynamespace::function()",
      "_ZN11mynamespace8functionEib" => "mynamespace::function(int, bool)",
      "_ZN11mynamespace8functionEPibPv" => "mynamespace::function(int*, bool, void*)",
      "_ZdlPv" => "operator delete(void*)"
    }
  end


  def self.subsuite
    suite = Test::Unit::TestSuite.new("C++ name demangler")
    suite << GCC3.suite
  end
end

