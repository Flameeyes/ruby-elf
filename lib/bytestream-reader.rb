# -*- coding: utf-8 -*-
# Simple bytestream reader.
# This class is a simple File derivative from which you can read
# integers of different sizes, in any endianness.
#
# Copyright © 2007-2010 Diego Elio Pettenò <flameeyes@flameeyes.com>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 

begin
  require 'readbytes'
rescue LoadError
end

module BytestreamReader
  # This exists in the documentation but not in implementation (?!)

  class UndefinedEndianness < Exception
    def initialize
      super("Requested default-endianness reads but no endianness defined")
    end
  end

  unless IO.instance_methods.include? "readbytes"
    def readexactly(length)
      ret = readpartial(length)

      # Not strictly correct on Ruby 1.8 but we don't care since we
      # only use this piece of compatibility code on 1.9.
      raise EOFError if ret.size != length

      return ret
    end
  else
    def readexactly(length)
      begin
        return readbytes(length)
      rescue TruncatedDataError
        raise EOFError
      end
    end
  end

  def read_array_u8(size)
    readexactly(1*size).unpack("C*")
  end

  def read_array_u16_be(size)
    readexactly(2*size).unpack("n*")
  end

  def read_array_u16_le(size)
    readexactly(2*size).unpack("v*")
  end

  def read_array_u32_be(size)
    readexactly(4*size).unpack("N*")
  end

  def read_array_u32_le(size)
    readexactly(4*size).unpack("V*")
  end

  def read_array_u64_be(size)
    buf = readexactly(8*size).unpack("N*")
    val = []
    size.times do |i|
      val[i] = buf[i*2] << 32 | buf[i*2+1];
    end
    return val
  end

  def read_array_u64_le(size)
    buf = readexactly(8*size).unpack("V*")
    val = []
    size.times do |i|
      val[i] = buf[i*2+1] << 32 | buf[i*2];
    end
    return val
  end

  def read_u8
    read_array_u8(1)[0]
  end

  def read_u16_be
    read_array_u16_be(1)[0]
  end

  def read_u16_le
    read_array_u16_le(1)[0]
  end

  def read_u32_be
    read_array_u32_be(1)[0]
  end

  def read_u32_le
    read_array_u32_le(1)[0]
  end

  def read_u64_be
    # As there is no direct unpack method for 64-bit words, the one-value
    # function is considered a special case.
    buf = readexactly(8).unpack("N*")
    return buf[0] << 32 | buf[1]
  end

  def read_u64_le
    # As there is no direct unpack method for 64-bit words, the one-value
    # function is considered a special case.
    buf = readexactly(8).unpack("V*")
    return buf[1] << 32 | buf[0]
  end

  def read_array_s8(size)
    readexactly(1*size).unpack("c*")
  end

  def read_array_s16_be(size)
    tmp = read_array_u16_be(size)
    tmp.collect { |val| (val & ~(1 << 15)) - (val & (1 << 15)) }
  end

  def read_array_s16_le(size)
    tmp = read_array_u16_le(size)
    tmp.collect { |val| (val & ~(1 << 15)) - (val & (1 << 15)) }
  end

  def read_array_s32_be(size)
    tmp = read_array_u32_be(size)
    tmp.collect { |val| (val & ~(1 << 31)) - (val & (1 << 31)) }
  end

  def read_array_s32_le(size)
    tmp = read_array_u32_le(size)
    tmp.collect { |val| (val & ~(1 << 31)) - (val & (1 << 31)) }
  end

  def read_array_s64_be(size)
    tmp = read_array_u64_be(size)
    tmp.collect { |val| (val & ~(1 << 63)) - (val & (1 << 63)) }
  end

  def read_array_s64_le(size)
    tmp = read_array_u64_le(size)
    tmp.collect { |val| (val & ~(1 << 63)) - (val & (1 << 63)) }
  end

  def read_s8
    tmp = read_u8
    return (tmp & ~(1 << 7)) - (tmp & (1 << 7))
  end

  def read_s16_be
    tmp = read_u16_be
    return (tmp & ~(1 << 15)) - (tmp & (1 << 15))
  end

  def read_s16_le
    tmp = read_u16_le
    return (tmp & ~(1 << 15)) - (tmp & (1 << 15))
  end

  def read_s32_be
    tmp = read_u32_be
    return (tmp & ~(1 << 31)) - (tmp & (1 << 31))
  end

  def read_s32_le
    tmp = read_u32_le
    return (tmp & ~(1 << 31)) - (tmp & (1 << 31))
  end

  def read_s64_be
    tmp = read_u64_be
    return (tmp & ~(1 << 63)) - (tmp & (1 << 63))
  end

  def read_s64_le
    tmp = read_u64_le
    return (tmp & ~(1 << 63)) - (tmp & (1 << 63))
  end

  BigEndian = :BigEndian
  LittleEndian = :LittleEndian

  def read_s16
    case @endian
    when BigEndian then read_s16_be
    when LittleEndian then read_s16_le
    else raise UndefinedEndianness.new
    end
  end

  def read_s32
    case @endian
    when BigEndian then read_s32_be
    when LittleEndian then read_s32_le
    else raise UndefinedEndianness.new
    end
  end

  def read_s64
    case @endian
    when BigEndian then read_s64_be
    when LittleEndian then read_s64_le
    else raise UndefinedEndianness.new
    end
  end

  def read_u16
    case @endian
    when BigEndian then read_u16_be
    when LittleEndian then read_u16_le
    else raise UndefinedEndianness.new
    end
  end

  def read_u32
    case @endian
    when BigEndian then read_u32_be
    when LittleEndian then read_u32_le
    else raise UndefinedEndianness.new
    end
  end

  def read_u64
    case @endian
    when BigEndian then read_u64_be
    when LittleEndian then read_u64_le
    else raise UndefinedEndianness.new
    end
  end

  def set_endian(endian)
    case endian
    when BigEndian, LittleEndian
      @endian = endian
    else
      raise ArgumentError.new
    end
  end

  # This is a commodity class of File that is simply extended with the
  # BytestreamReader.
  #
  # Right now it's only used for testing
  class File < ::File
    include BytestreamReader
  end
end
