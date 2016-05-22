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

require 'tempfile'

require 'elf/utils/pool'
require 'tt_elf'

# Test for Elf::Utilities::FilePool
class TC_File_Pool < Test::Unit::TestCase

  # Use hard-limit for open files (for stress)
  NOFILES = Process.getrlimit(Process::RLIMIT_NOFILE)[1] + 1

  def setup
    @pool = Elf::Utilities::FilePool

    @sample_file = get_test_file 'linux/x86/gcc/versioning.so'

    # for stress testing
    @dir = Dir.mktmpdir
    @filenames = (1..NOFILES).map { |n| "#{@dir}/elf_#{n}.so" }
    @filenames.each do |fn|
      FileUtils.copy_file @sample_file, fn
    end
  end

  def test_instance_reuse
    assert_same @pool[@sample_file], @pool[@sample_file]
  end

  def test_instance_recreate
    a = @pool[@sample_file]
    # ruby 2.2+: assert_false a.closed?
    assert !a.closed?
    a.close
    b = @pool[@sample_file]
    # ruby 2.2+: assert_false b.closed?
    assert !b.closed?
    assert_not_same a, b
  end

  def test_garbage_collected
    a = @pool[@sample_file].object_id
    GC.start
    b = @pool[@sample_file].object_id
    assert_not_equal a, b
  end

  # Just ensure that NOFILES is big enough
  def test_too_many_open_files
    # ruby 2.2+: assert_raise_message(/Too many open files/i)
    assert_raise(Errno::EMFILE) {
      open_files = @filenames.map { |fn| File.new fn }
    }
  end

  def test_stress
    ids = Hash.new { |h, k| h[k] = 0 }
    @filenames.each do |fn|
      ids[@pool[fn].object_id] += 1
    end
    # ruby 2.2+: assert_compare @filenames.length, '>', ids.length
    assert_not_equal @filenames.length, ids.length
    assert(@filenames.length > ids.length)
  end

  def teardown
    FileUtils.remove_entry @dir
  end
end
