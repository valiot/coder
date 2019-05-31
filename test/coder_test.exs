defmodule CoderTest do
  use ExUnit.Case
  use Coder
  doctest Coder

  test "Encode function" do
    assert encode("uint8", <<0xFF, 0xDC>>) == {255, <<0xDC>>}
    assert encode("int8", <<0xFF, 0xDC>>) == {-1, <<0xDC>>}
    assert encode("uint16_be", <<0x10, 0x01, 0x00, 0x00>>) == {0x1001, <<0x00, 0x00>>}
    assert encode("int16_be", <<0xF1, 0xF2, 0x00, 0x00>>) == {-3598, <<0x00, 0x00>>}
    assert encode("uint16_le", <<0x10, 0x01, 0x00, 0x00>>) == {0x0110, <<0x00, 0x00>>}
    assert encode("int16_le", <<0xF1, 0xF2, 0x00, 0x00>>) == {-3343, <<0x00, 0x00>>}
    assert encode("uint32_be", <<0x10, 0x01, 0x00, 0x00>>) == {0x10010000, ""}
    assert encode("int32_be", <<0xF0, 0x00, 0x00, 0x0F>>) == {-268_435_441, ""}
    assert encode("uint32_le", <<0x10, 0x01, 0x02, 0x00>>) == {0x00020110, ""}
    assert encode("int32_le", <<0x0F, 0x00, 0x00, 0xF0>>) == {-268_435_441, ""}
    assert encode("float32_be", <<0x42, 0xDC, 0x00, 0x00>>) == {110.0, ""}
    assert encode("float32_le", <<0x42, 0xDC, 0x00, 0x00>>) == {7.901361520941914e-41, ""}
    assert encode("ascii16_be", "ABCD") == {"AB", "CD"}
    assert encode("ascii16_le", "ABCD") == {"BA", "CD"}
    assert encode("ascii32_be", "ABCD") == {"ABCD", ""}
    assert encode("ascii32_le", "ABCD") == {"DCBA", ""}
  end

  test "Encode list function" do
    lt_type = [
      "uint16_be",
      "uint16_le",
      "int16_be",
      "int16_le",
      "ascii16_be",
      "ascii16_le",
      "uint32_be",
      "uint32_le",
      "int32_be",
      "int32_le",
      "ascii32_le",
      "ascii32_be",
      "float32_be",
      "float32_le"
    ]

    lt_values = [
      1,
      0xFFFF,
      0xFFFF,
      0,
      0,
      0,
      0x42DC,
      0,
      0x42DC,
      0,
      0x42DC,
      0,
      0x42DC,
      0,
      0,
      0xFF,
      0x3332,
      0x3233,
      0x42DC,
      0,
      0x42DC,
      0
    ]

    assert encode_list(lt_type, lt_values, 16) == [
             1,
             65535,
             -1,
             0,
             <<0, 0>>,
             <<0, 0>>,
             1_121_714_176,
             56386,
             1_121_714_176,
             56386,
             <<255, 0, 0, 0>>,
             "3223",
             110.0,
             7.901361520941914e-41
           ]
  end

  test "Encode string function" do
    lt_type = [
      "uint8",
      "int8",
      "uint16_be",
      "uint16_le",
      "int16_be",
      "int16_le",
      "ascii16_be",
      "ascii16_le",
      "uint32_be",
      "uint32_le",
      "int32_be",
      "int32_le",
      "ascii32_le",
      "ascii32_be",
      "float32_be",
      "float32_le"
    ]

    lt_values = <<
      0xFF,
      0x1F,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00,
      0x42,
      0xDC,
      0x00,
      0x00
    >>

    assert encode_all(lt_type, lt_values, []) == [
             255,
             31,
             65535,
             65535,
             -1,
             0,
             <<0, 0>>,
             <<0, 0>>,
             1_121_714_176,
             56386,
             1_121_714_176,
             56386,
             <<0, 0, 220, 66>>,
             <<66, 220, 0, 0>>,
             110.0,
             7.901361520941914e-41
           ]
  end

  test "Decode all supported data types" do
    assert decode("uint8", 65500) == <<0xDC>>
    assert decode("int8", 65500) == <<0xDC>>
    assert decode("uint16_be", 10992) == <<42, 240>>
    assert decode("int16_be", 68768) ==  <<12, 160>>
    assert decode("uint16_le", 10992) == <<240, 42>>
    assert decode("int16_le", 68768) ==  <<160, 12>>
    assert decode("uint32_be", 268500992) == <<0x10, 0x01, 0x00, 0x00>>
    assert decode("int32_be", 4059168768) == <<0xF1, 0xF2, 0x00, 0x00>>
    assert decode("uint32_le", 268500992) == <<0x00, 0x00, 0x01, 0x10>>
    assert decode("int32_le", 4059168768) == <<0x00, 0x00, 0xF2, 0xF1>>

    assert decode("float32_be", 5.0) == <<64, 160, 0, 0>>
    assert decode("float32_be", -5.0) ==  <<192, 160, 0, 0>>
    assert decode("float32_le", 5.0) == <<0, 0, 160, 64>>
    assert decode("float32_le", -5.0) == <<0, 0, 160, 192>>
  end

  test "Decode function rounds float input" do
    assert decode("int32_be", 5.5) == <<0, 0, 0, 6>>
    assert decode("float32_be", -5.0) ==  <<192, 160, 0, 0>>
  end

  test "Decode a number into a list of words" do
    float_bin = decode("float32_be", 110.0)
    lt_bin = binary_to_list(float_bin, [])
    assert lt_bin == [17116, 0]

    float_bin = decode("float32_le", 110.0)
    lt_bin = binary_to_list(float_bin, [])
    assert lt_bin == [0, 56386]

    int_bin = decode("int32_be", 110.0)
    lt_bin = binary_to_list(int_bin, [])
    assert lt_bin == [0, 110]

    int_bin = decode("int32_le", 110.0)
    lt_bin = binary_to_list(int_bin, [])
    assert lt_bin == [28160, 0]

    int_bin = decode("int8", 110.0)
    lt_bin = binary_to_list(int_bin, [])
    assert lt_bin == [110]
  end
end
