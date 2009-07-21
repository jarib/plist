require "test/unit"
require "plist"

class TestBinary < Test::Unit::TestCase
  def test_binary_min_byte_size
    # 1-, 2-, and 4-byte integers are unsigned.
    assert_equal(1, Plist::Binary.send(:min_byte_size, 0))
    assert_equal(1, Plist::Binary.send(:min_byte_size, 0xff))
    assert_equal(2, Plist::Binary.send(:min_byte_size, 0x100))
    assert_equal(2, Plist::Binary.send(:min_byte_size, 0xffff))
    assert_equal(4, Plist::Binary.send(:min_byte_size, 0x10000))
    assert_equal(4, Plist::Binary.send(:min_byte_size, 0xffffffff))
    # 8- and 16-byte integers are signed.
    assert_equal(8, Plist::Binary.send(:min_byte_size, 0x100000000))
    assert_equal(8, Plist::Binary.send(:min_byte_size, 0x7fffffffffffffff))
    assert_equal(16, Plist::Binary.send(:min_byte_size, 0x8000000000000000))
    assert_equal(16, Plist::Binary.send(:min_byte_size, 0x7fffffffffffffffffffffffffffffff))
    assert_raises(RangeError) { Plist::Binary.send(:min_byte_size, 0x80000000000000000000000000000000) }
    assert_equal(8, Plist::Binary.send(:min_byte_size, -1))
    assert_equal(8, Plist::Binary.send(:min_byte_size, -0x8000000000000000))
    assert_equal(16, Plist::Binary.send(:min_byte_size, -0x8000000000000001))
    assert_equal(16, Plist::Binary.send(:min_byte_size, -0x80000000000000000000000000000000))
    assert_raises(RangeError) { Plist::Binary.send(:min_byte_size, -0x80000000000000000000000000000001) }
  end
  
  def test_binary_pack_int
    assert_equal("\x0", Plist::Binary.send(:pack_int, 0, 1))
    assert_equal("\x0\x34", Plist::Binary.send(:pack_int, 0x34, 2))
    assert_equal("\x0\xde\xdb\xef", Plist::Binary.send(:pack_int, 0xdedbef, 4))
    assert_equal("\x0\xca\xfe\x0\x0\xde\xdb\xef", Plist::Binary.send(:pack_int, 0xcafe0000dedbef, 8))
    assert_equal("\x0\x7f\xf7\x0\x0\x12\x34\x0\x0\xca\xfe\x0\x0\xde\xdb\xef", Plist::Binary.send(:pack_int, 0x7ff7000012340000cafe0000dedbef, 16))
    assert_raises(ArgumentError) { Plist::Binary.send(:pack_int, -1, 1) }
    assert_raises(ArgumentError) { Plist::Binary.send(:pack_int, -1, 2) }
    assert_raises(ArgumentError) { Plist::Binary.send(:pack_int, -1, 4) }
    assert_equal("\xff\xff\xff\xff\xff\xff\xff\xff", Plist::Binary.send(:pack_int, -1, 8))
    assert_equal("\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff", Plist::Binary.send(:pack_int, -1, 16))
    [-2,0,3,5,6,7,9,10,11,12,13,14,15,17,18,19,20,32].each do |i|
      assert_raises(ArgumentError) { Plist::Binary.send(:pack_int, 0, i) }
    end
  end
end
