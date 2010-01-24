# -*- coding: utf-8 -*-
# Copyright © 2009-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# Test for symbol comparison
#
# This series of tests is supposed to compare symbols from different
# objects to ensure that they can be properly identified as compatible
# or not.
class TC_Symbols_Comparison < Test::Unit::TestCase
  def setup
    @versioned_library = Elf::File.new(Elf::BaseTest::TestDir + "linux/amd64/gcc/versioning.so")
    @unversioned_library = Elf::File.new(Elf::BaseTest::TestDir + "linux/amd64/gcc/versioning-unversioned.so")
    @versioned_user = Elf::File.new(Elf::BaseTest::TestDir + "linux/amd64/gcc/versioning-user-versioned")

    @versioned_asymbol_base = @versioned_library[".dynsym"].
      find { |sym| sym.name == "asymbol" and sym.version == nil }
    @versioned_asymbol_versioned = @versioned_library[".dynsym"].
      find { |sym| sym.name == "asymbol" and sym.version == "VERSION1" }
    @unversioned_asymbol = @unversioned_library[".dynsym"].
      find { |sym| sym.name == "asymbol" }
    @user_asymbol_versioned = @versioned_user[".dynsym"].
      find { |sym| sym.name == "asymbol" and sym.version == "VERSION1" }
  end

  def test_equality_same_object
    assert((@versioned_asymbol_base == @versioned_asymbol_base))
    assert(@versioned_asymbol_versioned == @versioned_asymbol_versioned)
  end

  def test_equality2_same_object
    assert((@versioned_asymbol_base.eql? @versioned_asymbol_base))
    assert(@versioned_asymbol_versioned.eql? @versioned_asymbol_versioned)
  end

  def test_inequality_same_object
    assert(!(@versioned_asymbol_base != @versioned_asymbol_base))
    assert(!(@versioned_asymbol_versioned != @versioned_asymbol_versioned))
  end

  def test_not_equality_same_object
    assert(!(@versioned_asymbol_base == @versioned_asymbol_versioned))
    assert(!(@versioned_asymbol_versioned == @versioned_asymbol_base))
  end

  def test_not_equality2_same_object
    assert(!(@versioned_asymbol_base.eql? @versioned_asymbol_versioned))
    assert(!(@versioned_asymbol_versioned.eql? @versioned_asymbol_base))
  end

  def test_not_inequality_same_object
    assert((@versioned_asymbol_base != @versioned_asymbol_versioned))
    assert((@versioned_asymbol_versioned != @versioned_asymbol_base))
  end

  def test_equality_different_objects
    assert((@versioned_asymbol_base == @unversioned_asymbol))
    assert((@unversioned_asymbol == @versioned_asymbol_base))
  end

  def test_equality2_different_objects
    assert((@versioned_asymbol_base.eql? @unversioned_asymbol))
    assert((@unversioned_asymbol.eql? @versioned_asymbol_base))
  end

  def test_inequality_different_objects
    assert(!(@versioned_asymbol_base != @unversioned_asymbol))
    assert(!(@unversioned_asymbol != @versioned_asymbol_base))
  end

  def test_not_equality_different_objects
    assert(!(@versioned_asymbol_versioned == @unversioned_asymbol))
    assert(!(@unversioned_asymbol == @versioned_asymbol_versioned))
  end

  def test_not_equality2_different_objects
    assert(!(@versioned_asymbol_versioned.eql? @unversioned_asymbol))
    assert(!(@unversioned_asymbol.eql? @versioned_asymbol_versioned))
  end

  def test_not_inequality_different_objects
    assert((@versioned_asymbol_versioned != @unversioned_asymbol))
    assert((@unversioned_asymbol != @versioned_asymbol_versioned))
  end

  def test_not_compatibility_same_object
    assert(!(@versioned_asymbol_base =~ @versioned_asymbol_versioned))
    assert(!(@versioned_asymbol_versioned =~ @versioned_asymbol_base))
  end

  def test_not_incompatibility_same_object
    assert((@versioned_asymbol_base !~ @versioned_asymbol_versioned))
    assert((@versioned_asymbol_versioned !~ @versioned_asymbol_base))
  end

  def test_compatibility_different_objects
    assert((@user_asymbol_versioned =~ @versioned_asymbol_versioned))
    assert((@versioned_asymbol_versioned =~ @user_asymbol_versioned))
  end

  def test_incompatibility_different_objects
    assert(!(@user_asymbol_versioned !~ @versioned_asymbol_versioned))
    assert(!(@versioned_asymbol_versioned !~ @user_asymbol_versioned))
  end

  def test_not_compatibility_different_objects
    assert(!(@user_asymbol_versioned =~ @versioned_asymbol_base))
    assert(!(@versioned_asymbol_base =~ @user_asymbol_versioned))
  end

  def test_not_incompatibility_different_objects
    assert((@user_asymbol_versioned !~ @versioned_asymbol_base))
    assert((@versioned_asymbol_base !~ @user_asymbol_versioned))
  end
end
