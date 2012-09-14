# -*- coding: utf-8 -*-
# Copyright © 2007-2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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
require 'stringio'

class TC_IOFrontend < Test::Unit::TestCase
  # We cannot use the fileno count trick on JRuby :(
  if RUBY_PLATFORM != "java"
    # Define setup and teardown functions to make sure that no
    # descriptors are leaked during the tests. We don't want descriptors
    # to leak when exception happens, otherwise we likely have a bug in
    # the code.
    def setup
      file = File.new(get_test_file("invalid/nonelf"))
      @fileno_before = file.fileno
      file.close
    end

    def teardown
      file = File.new(get_test_file("invalid/nonelf"))
      @fileno_after = file.fileno
      file.close

      assert_equal(@fileno_before, @fileno_after,
                   "Descriptor leaked!")
    end
  else
    $stderr.puts "Unable to test for file descriptor leaks on JRuby"
  end

  def test_path
    elf = Elf::File.new(get_test_file("linux/amd64/gcc/dynamic_executable"))
    elf.close
  end

  def test_file
    file = File.new(get_test_file("linux/amd64/gcc/dynamic_executable"))
    elf = Elf::File.new(file)
    elf.close
  end

  def test_stringio
    file = File.new(get_test_file("linux/amd64/gcc/dynamic_executable"))
    elf = Elf::File.new(StringIO.new(file.read, "r"))
    elf.close
    file.close
  end
end
