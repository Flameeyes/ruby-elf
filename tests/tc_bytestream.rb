# Tests for the bytestrem reader
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

require 'test/unit'
require 'tempfile'

require 'bytestream-reader'

class TC_Bytestream < Test::Unit::TestCase
  TestFile = \
  "\x01\x23\x45\x56" \
  "\x89\x67\x45\x23" \
  "\xFF\xFF\xAB\xCD"

  TestValues_u16le = [ 0x2301, 0x5645, 0x6789, 0x2345, 0xFFFF, 0xCDAB ]
  TestValues_u16be = [ 0x0123, 0x4556, 0x8967, 0x4523, 0xFFFF, 0xABCD ]
  TestValues_u32le = [ 0x56452301, 0x23456789, 0xCDABFFFF ]
  TestValues_u32be = [ 0x01234556, 0x89674523, 0xFFFFABCD ]
  TestValue_u64le = 0x2345678956452301
  TestValue_u64be = 0x0123455689674523

  def setup
    @tf = Tempfile.new("tc_bytestream")
    
    @tf.write(TestFile)
    @tf.close

    @bs = BytestreamReader.new(@tf.path)
  end

  def teardown
    @bs.close
    @tf.unlink
  end

  def test_readbytes
    assert( @bs.readbytes(12) == TestFile,
            "The content of the file does not coincide.")
  end

  def test_read_u8
    i = 0
    12.times do
      assert( @bs.read_u8 == TestFile[i],
              "Byte of index #{i} does not coincide." )
      i += 1
    end
  end

  def test_read_u16_le
    i = 0
    6.times do
      assert( @bs.read_u16_le == TestValues_u16le[i],
              "16-bit LE word of index #{i} does not coincide" )
      i += 1
    end
  end

  def test_read_u16_be
    i = 0
    6.times do
      assert( @bs.read_u16_be == TestValues_u16be[i],
              "16-bit BE word of index #{i} does not coincide" )
      i += 1
    end
  end

  def test_read_u32_le
    i = 0
    3.times do
      assert( @bs.read_u32_le == TestValues_u32le[i],
              "32-bit LE word of index #{i} does not coincide" )
      i += 1
    end
  end

  def test_read_u32_be
    i = 0
    3.times do
      assert( @bs.read_u32_be == TestValues_u32be[i],
              "32-bit BE word of index #{i} does not coincide" )
      i += 1
    end
  end

  def test_read_u64_le
    assert( @bs.read_u64_le == TestValue_u64le,
            "64-bit LE word does not coincide" )
  end

  def test_read_u64_be
    assert( @bs.read_u64_be == TestValue_u64be,
            "64-bit BE word does not coincide" )
  end

  def test_endian_le
    @bs.set_endian(BytestreamReader::LittleEndian)
    assert( @bs.read_u16 == TestValues_u16le[0],
            "16-bit (LE) word of index 0 does not coincide.")
    @bs.read_u16 # Ignore this, should check for 16-bit signed though
    assert( @bs.read_u32 == TestValues_u32le[1],
            "32-bit (LE) word of index 1 does not coincide.")
    @bs.read_u32 # Ignore this, should check for 32-bit signed though
  end

  def test_endian_be
    @bs.set_endian(BytestreamReader::BigEndian)
    assert( @bs.read_u16 == TestValues_u16be[0],
            "16-bit (BE) word of index 0 does not coincide.")
    @bs.read_u16 # Ignore this, should check for 16-bit signed though
    assert( @bs.read_u32 == TestValues_u32be[1],
            "32-bit (BE) word of index 1 does not coincide.")
    @bs.read_u32 # Ignore this, should check for 32-bit signed though
  end

end
