defmodule DecoderTest do
  use ExUnit.Case
  use Decoder
  doctest Decoder

  test "Decode function" do
    assert decode("uint8", <<0xFF, 0xDC>>) == {255, <<0xDC>>}
    assert decode("int8", <<0xFF, 0xDC>>) == {-1, <<0xDC>>}
    assert decode("uint16_be", <<0x10, 0x01, 0x00, 0x00>>) == {0x1001, <<0x00, 0x00>>}
    assert decode("int16_be", <<0xF1, 0xF2, 0x00, 0x00>>) == {-3598, <<0x00, 0x00>>}
    assert decode("uint16_le", <<0x10, 0x01, 0x00, 0x00>>) == {0x0110, <<0x00, 0x00>>}
    assert decode("int16_le", <<0xF1, 0xF2, 0x00, 0x00>>) == {-3343, <<0x00, 0x00>>}
    assert decode("uint32_be", <<0x10, 0x01, 0x00, 0x00>>) == {0x10010000, ""}
    assert decode("int32_be", <<0xF0, 0x00, 0x00, 0x0F>>) == {-268_435_441, ""}
    assert decode("uint32_le", <<0x10, 0x01, 0x02, 0x00>>) == {0x00020110, ""}
    assert decode("int32_le", <<0x0F, 0x00, 0x00, 0xF0>>) == {-268_435_441, ""}
    assert decode("float32_be", <<0x42, 0xDC, 0x00, 0x00>>) == {110.0, ""}
    assert decode("float32_le", <<0x42, 0xDC, 0x00, 0x00>>) == {7.901361520941914e-41, ""}
    assert decode("ascii16_be", "ABCD") == {"AB", "CD"}
    assert decode("ascii16_le", "ABCD") == {"BA", "CD"}
    assert decode("ascii32_be", "ABCD") == {"ABCD", ""}
    assert decode("ascii32_le", "ABCD") == {"DCBA", ""}
  end

  test "Decode list function" do
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

    assert decode_list(lt_type, lt_values, 16) == [
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

  test "Decode string function" do
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

    assert decode_all(lt_type, lt_values, []) == [
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
end
