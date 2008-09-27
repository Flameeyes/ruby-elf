# Copyright 2007, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require Pathname.new(__FILE__).dirname + 'tc_bytestream'
require Pathname.new(__FILE__).dirname + 'tc_dynamic_executable'
require Pathname.new(__FILE__).dirname + 'tc_static_executable'
require Pathname.new(__FILE__).dirname + 'tc_relocatable'
require Pathname.new(__FILE__).dirname + 'tc_exceptions'
require Pathname.new(__FILE__).dirname + 'tc_arm'
require Pathname.new(__FILE__).dirname + 'tc_sunw_sections'
require Pathname.new(__FILE__).dirname + 'tc_versioning'
require Pathname.new(__FILE__).dirname + 'tc_solaris_versioning'
