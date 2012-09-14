# -*- coding: utf-8 -*-
# Tests for the ar format reader
#
# Copyright © 2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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

require 'ar'
require 'tt_elf'

class TC_AR < Test::Unit::TestCase
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

  # Helper to check for exceptions on opening a file.
  def helper_open_exception(exception_class, subpath)
    assert_raise exception_class do
      Ar::File.new(get_test_file("invalid/#{subpath}"))
    end
  end

  # Test behaviour when a file is requested that is not present.
  #
  # Expected behaviour: Errno::ENOENT exception is raised
  def test_nofile
    filepath = get_test_file("invalid/notfound")

    # Check that the file does not exist or we're going to throw an
    # exception to signal an error in the test.
    if File.exists?(filepath)
      raise Exception.new("File '#{filepath}' present in the test directory.")
    end

    helper_open_exception Errno::ENOENT, "notfound"
  end

  # Test behaviour when a file that is not an AR file is opened.
  #
  # Expected behaviour: Ar::File::NotAnAR exception is raised.
  def test_notanar
    helper_open_exception Ar::File::NotAnAR, "nonelf"
  end

  # Test behaviour when a file too short to be an AR file is opened
  # (that has not enough data to read the eight magic bytes at the
  # start of the file).
  #
  # Expected behaviour: Ar::File::NotAnAR exception is raised.
  def test_shortfile
    helper_open_exception Ar::File::NotAnAR, "shortfile"
  end

  # Test behaviour when opening a named pipe (fifo) path
  #
  # Expected behaviour: Errno::EINVAL exception is raised
  def test_named_pipe
    # Since we cannot add the pipe to the git repository, we've got to
    # create one ourselves :(
    pipedir = File.expand_path("ruby-elf-tests-#{Process.pid}-#{Time.new.strftime("%s")}", Dir.tmpdir)
    pipepath = File.expand_path("fifo", pipedir)
    begin
      Dir.mkdir(pipedir)
      system("mkfifo #{pipepath}")

      assert_raise Errno::EINVAL do
        Ar::File.new(pipepath)
      end
    ensure
      FileUtils.rmtree(pipedir)
    end
  end

  # Test behaviour when opening a file too short to contain a file
  # header.
  def test_truncated
    helper_open_exception Errno::ENODATA, "truncatedarchive"
  end

  # Test behaviour when opening a file that has an invalid
  # end-of-header signature.
  def test_invalidendfile
    helper_open_exception Ar::File::NotAnAR, "invalidendfile"
  end

  # Test access of a simple simplifed file
  def test_singlefile
    ar = Ar::File.new(get_test_file("archive/singlefile.a"))
    assert_equal 1, ar.files_count
    file = ar[0]

    # check the file's header
    assert_equal "shortfile", file.name
    assert_equal 501, file.owner
    assert_equal 1005, file.group
    assert_equal 0100644, file.mode #octal
    assert_equal 2, file.size

    # make sure that it was inserted into the index correctly
    assert_equal file, ar["shortfile"]
  ensure
    ar.close unless ar.nil?
  end

  def _test_longfilename(variant)
    ar = Ar::File.new(get_test_file("archive/longfilename-#{variant}.a"))
    assert_equal 1, ar.files_count
    file = ar[0]

    assert_equal "thisisaveryveryverylongfilenameandithastobeencodedwiththeextendedformattoworkcorrectly", file.name
    
    assert_equal ar["thisisaveryveryverylongfilenameandithastobeencodedwiththeextendedformattoworkcorrectly"], file
  ensure
    ar.close unless ar.nil?
  end

  # Test access of a file with GNU long file names
  def test_longfilename_gnu
    _test_longfilename("gnu")
  end

  # Test access of a file with Apple long file names
  def test_longfilename_apple
    _test_longfilename("apple")
  end

  # Test access of a file with libarchive/bsdtar long file names
  def test_longfilename_libarchive
    _test_longfilename("libarchive")
  end

  def _test_objects(variant)
    ar = Ar::File.new(get_test_file("archive/objects-#{variant}.a"))
    assert_equal 3, ar.files_count
  ensure
    ar.close unless ar.nil?
  end

  # Test access of a file with real objects (GNU ar)
  def test_objects_gnu
    _test_objects("gnu")
  end

  # Test access of a file with real objects (Apple ar)
  def test_objects_apple
    _test_objects("apple")
  end

  # Test access of a file with real objects (libarchive/bsdtar)
  def test_objects_libarchive
    _test_objects("libarchive")
  end
end
