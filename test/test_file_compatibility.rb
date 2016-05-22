# -*- coding: utf-8 -*-
# Copyright © 2015 Nikolay Orliuk <virkony@gmail.com>
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

require 'tt_elf'

# Test for ELF files compatibility

class TC_File_Compatibility < Test::Unit::TestCase
  def open_sample(name)
    Elf::File.new(get_test_file(name))
  end

  def setup
    @linux_class64 = open_sample 'linux/amd64/gcc/gnu_specific'
    @sysv_class64 = open_sample 'linux/amd64/gcc/versioning-unversioned.so'
    @sysv_class32 = open_sample 'linux/x86/gcc/versioning.so'
    @class32 = [@linux_class64, @sysv_class64]
  end
  def compatible_pairs
    class64 = [@linux_class64, @sysv_class64]
    class64.product(class64) { |x, y| yield x, y }

    yield @sysv_class32, @sysv_class32
  end
  def incompatible_pairs
    class64 = [@linux_class64, @sysv_class64]
    class64.each { |x| yield x, @sysv_class32; yield @sysv_class32, x }
  end

  def test_compatible
    compatible_pairs do |left, right|
      assert left.is_compatible(right), "#{left.path} should be compatible with #{right.path}"
    end
  end
  def test_incompatible
    incompatible_pairs do |left, right|
      assert !left.is_compatible(right), "#{left.path} should NOT be compatible with #{right.path}"
    end
  end
end

# ex: et:sw=2
