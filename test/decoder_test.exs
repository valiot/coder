defmodule DecoderTest do
  use ExUnit.Case
  doctest Decoder

  test "greets the world" do
    assert Decoder.hello() == :world
  end
end
