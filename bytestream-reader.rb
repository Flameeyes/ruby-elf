# Simple bytestream reader.
# This class is a simple File derivative from which you can read
# integers of different sizes, in any endianness.
#
# Copyright 2007 Diego Pettenò <flameeyes@gmail.com>
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

class BytestreamReader < File
  # This exists in the documentation but not in implementation (?!)

  class TruncatedDataError < Exception
    def initialize(req, got)
      @req = req; @got = got
    end

    def message
      "The read data (#{@got}) is not the same amount as requested (#{@req})."
    end
  end

  def readbytes(req)
    buf = ''
    n = req

    loop do
      new = readpartial(n)
      buf += new
      
      break if buf.size >= req

      raise TruncateDataError.new(req, buf.size) if new.size == 0
      
      n -= new.size
    end

    return buf
  end

  def read_u8
    buf = readbytes(1)[0]
  end

  def read_u16_be
    readbytes(2).unpack("n*")[0]
  end

  def read_u16_le
    readbytes(2).unpack("v*")[0]
  end

  def read_u32_be
    readbytes(4).unpack("N*")[0]
  end

  def read_u32_le
    readbytes(4).unpack("V*")[0]
  end

  def read_u64_be
    buf = readbytes(8).unpack("N*")
    return buf[0] << 32 | buf[1]
  end

  def read_u64_le
    buf = readbytes(8).unpack("V*")
    return buf[1] << 32 | buf[0]
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
    end
  end

  def read_s32
    case @endian
    when BigEndian then read_s32_be
    when LittleEndian then read_s32_le
    end
  end

  def read_s64
    case @endian
    when BigEndian then read_s64_be
    when LittleEndian then read_s64_le
    end
  end

  def read_u16
    case @endian
    when BigEndian then read_u16_be
    when LittleEndian then read_u16_le
    end
  end

  def read_u32
    case @endian
    when BigEndian then read_u32_be
    when LittleEndian then read_u32_le
    end
  end

  def read_u64
    case @endian
    when BigEndian then read_u64_be
    when LittleEndian then read_u64_le
    end
  end

  def set_endian(endian)
    case endian
    when BigEndian, LittleEndian
      @endian = endian
    else
      raise InvalidArgument
    end
  end
end
