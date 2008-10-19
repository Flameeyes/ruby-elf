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
  "\xFF\xFF\xAB\xCD" \
  "\x87\x98\x23\x34"

  TestValues_u16le = [ 0x2301, 0x5645, 0x6789, 0x2345, 0xFFFF, 0xCDAB ]
  TestValues_u16be = [ 0x0123, 0x4556, 0x8967, 0x4523, 0xFFFF, 0xABCD ]
  TestValues_u32le = [ 0x56452301, 0x23456789, 0xCDABFFFF ]
  TestValues_u32be = [ 0x01234556, 0x89674523, 0xFFFFABCD ]
  TestValue_u64le = 0x2345678956452301
  TestValue_u64be = 0x0123455689674523

  @@x = 0xdeadbeef
  
  @@endian_types = {
    Array(@@x).pack("V*") => :little,
    Array(@@x).pack("N*") => :big
  }
  @@endian = @@endian_types[Array(@@x).pack("L*")]

  def setup
    @tf = Tempfile.new("tc_bytestream")
    
    @tf.write(TestFile)
    @tf.close

    @bs = BytestreamReader::File.new(@tf.path)
  end

  def teardown
    @bs.close
    @tf.unlink
  end

  def test_readbytes
    assert_equal(TestFile, @bs.readbytes(16),
                 "The content of the file does not coincide.")
  end

  def test_read_array_u8
    assert_equal(TestFile.unpack("C*"), @bs.read_array_u8(TestFile.size),
                 "The content of the 8-bit array does not coincide.")
  end

  def test_read_u8
    i = 0
    12.times do
      assert_equal(TestFile[i], @bs.read_u8,
                   "Byte of index #{i} does not coincide." )
      i += 1
    end
  end

  # Only test current endian, for now.
  def test_read_array_u16
    if @@endian == :little
      assert_equal(TestFile.unpack("S*"), @bs.read_array_u16_le(TestFile.size/2),
                   "The content of the 16-bit array does not coincide.")
    else
      assert_equal(TestFile.unpack("S*"), @bs.read_array_u16_be(TestFile.size/2),
                   "The content of the 16-bit array does not coincide.")
    end
  end

  def test_read_u16_le
    i = 0
    6.times do
      assert_equal(TestValues_u16le[i], @bs.read_u16_le,
                   "16-bit LE word of index #{i} does not coincide" )
      i += 1
    end
  end

  def test_read_u16_be
    i = 0
    6.times do
      assert_equal( TestValues_u16be[i], @bs.read_u16_be,
                    "16-bit BE word of index #{i} does not coincide" )
      i += 1
    end
  end

  # Only test current endian, for now.
  def test_read_array_u32
    if @@endian == :little
      assert_equal( TestFile.unpack("L*"), @bs.read_array_u32_le(TestFile.size/4),
              "The content of the 16-bit array does not coincide.")
    else
      assert_equal( TestFile.unpack("L*"), @bs.read_array_u32_be(TestFile.size/4),
                    "The content of the 16-bit array does not coincide.")
    end
  end

  def test_read_u32_le
    i = 0
    3.times do
      assert_equal( TestValues_u32le[i], @bs.read_u32_le,
                    "32-bit LE word of index #{i} does not coincide" )
      i += 1
    end
  end

  def test_read_u32_be
    i = 0
    3.times do
      assert_equal( TestValues_u32be[i], @bs.read_u32_be,
                    "32-bit BE word of index #{i} does not coincide" )
      i += 1
    end
  end

  # Only test current endian, for now.
  def test_read_array_u64
    if @@endian == :little
      assert_equal( TestFile.unpack("Q*"), @bs.read_array_u64_le(TestFile.size/8),
                    "The content of the 16-bit array does not coincide.")
    else
      assert_equal( TestFile.unpack("Q*"), @bs.read_array_u64_be(TestFile.size/8),
                    "The content of the 16-bit array does not coincide.")
    end
  end

  def test_read_u64_le
    assert_equal( TestValue_u64le, @bs.read_u64_le,
                  "64-bit LE word does not coincide" )
  end

  def test_read_u64_be
    assert_equal( TestValue_u64be, @bs.read_u64_be,
                  "64-bit BE word does not coincide" )
  end

  def test_read_array_s8
    assert_equal( TestFile.unpack("c*"), @bs.read_array_s8(TestFile.size),
                  "The content of the file does not coincide.")
  end

  # Only test current endian, for now.
  def test_read_array_s16
    if @@endian == :little
      assert_equal( TestFile.unpack("s*"), @bs.read_array_s16_le(TestFile.size/2),
                    "The content of the 16-bit array does not coincide.")
    else
      assert_equal( TestFile.unpack("s*"), @bs.read_array_s16_be(TestFile.size/2),
                    "The content of the 16-bit array does not coincide.")
    end
  end

  # Only test current endian, for now.
  def test_read_array_s32
    if @@endian == :little
      assert_equal( TestFile.unpack("l*"), @bs.read_array_s32_le(TestFile.size/4),
                    "The content of the 16-bit array does not coincide.")
    else
      assert_equal( TestFile.unpack("l*"), @bs.read_array_s32_be(TestFile.size/4),
                    "The content of the 16-bit array does not coincide.")
    end
  end

  # Only test current endian, for now.
  def test_read_array_s64
    if @@endian == :little
      assert_equal( TestFile.unpack("q*"), @bs.read_array_s64_le(TestFile.size/8),
                    "The content of the 16-bit array does not coincide.")
    else
      assert_equal( TestFile.unpack("q*"), @bs.read_array_s64_be(TestFile.size/8),
                    "The content of the 16-bit array does not coincide.")
    end
  end

  def test_endian_le
    @bs.set_endian(BytestreamReader::LittleEndian)
    assert_equal( TestValues_u16le[0], @bs.read_u16,
                  "16-bit (LE) word of index 0 does not coincide.")
    @bs.read_u16 # Ignore this, should check for 16-bit signed though
    assert_equal( TestValues_u32le[1], @bs.read_u32,
                  "32-bit (LE) word of index 1 does not coincide.")
    @bs.read_u32 # Ignore this, should check for 32-bit signed though
  end

  def test_endian_be
    @bs.set_endian(BytestreamReader::BigEndian)
    assert_equal( TestValues_u16be[0], @bs.read_u16,
                  "16-bit (BE) word of index 0 does not coincide.")
    @bs.read_u16 # Ignore this, should check for 16-bit signed though
    assert_equal( TestValues_u32be[1], @bs.read_u32,
                  "32-bit (BE) word of index 1 does not coincide.")
    @bs.read_u32 # Ignore this, should check for 32-bit signed though
  end

  # Test the behaviour of BytestreamReader when asking to read with
  # default endian but no endian was provided.
  def test_no_endian_u16
    assert_raise BytestreamReader::UndefinedEndianness do
      @bs.read_u16
    end
  end

  def test_no_endian_u32
    assert_raise BytestreamReader::UndefinedEndianness do
      @bs.read_u32
    end
  end

  def test_no_endian_u64
    assert_raise BytestreamReader::UndefinedEndianness do
      @bs.read_u64
    end
  end

  def test_no_endian_s16
    assert_raise BytestreamReader::UndefinedEndianness do
      @bs.read_s16
    end
  end

  def test_no_endian_s32
    assert_raise BytestreamReader::UndefinedEndianness do
      @bs.read_s32
    end
  end

  def test_no_endian_s64
    assert_raise BytestreamReader::UndefinedEndianness do
      @bs.read_s64
    end
  end

  # Test the behaviour of BytestreamReader when providing an invalid
  # endianness value.
  def test_invalid_endian
    assert_raise ArgumentError do
      @bs.set_endian("foobar")
    end
  end
end
