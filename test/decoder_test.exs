defmodule DecoderTest do
  use ExUnit.Case
  use Decoder
  doctest Decoder

  test "greets the world" do
    assert Decoder.decode_all("float32_be", <<0x42, 0xDC, 0x00, 0x00>>, []) == {[110.0], ""}
  end
end
