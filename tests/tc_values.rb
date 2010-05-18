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

require 'test/unit'
require 'elf'

# Test for Value classes to return the correct values when requesting
# OS- or Processor-specific values.
class TC_Values < Test::Unit::TestCase
  def test_symbol_binding
    assert_equal Elf::Symbol::Binding[0], Elf::Symbol::Binding::Local

    x = Elf::Symbol::Binding[14]
    assert_equal x.class, Elf::Value::Unknown
    assert_equal x.to_s, "STB_LOPROC+0000001"
  end
end
