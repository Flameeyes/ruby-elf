# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007-2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>
# Copyright © 2012 Kelly Dunn <defaultstring@gmail.com>
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

module Elf
  class ProgramHeader
    attr_reader :idx, :type, :offset, :virtual_address, :physical_address,
                :file_size, :memory_size, :flags, :alignment

    def initialize(data)
      @idx = data[:idx]
      @type = data[:type_id]
      @offset = data[:offset]
      @virtual_address = data[:virtual_address]
      @physical_address = data[:physical_address]
      @file_size = data[:file_size]
      @memory_size = data[:memory_size]
      @flags = data[:flags]
      @alignment = data[:alignment]
    end
  end
end
