defmodule IntegrationTest do
  use ExUnit.Case
  use Coder
  doctest Coder

  test "Encode function" do
    binary = <<5, 233, 0, 1>>
    swap_type_list = ["1032"]
    new_order = change_bytes_string_order(swap_type_list, binary)
    expected_order = <<0, 1, 5, 233>>
    assert new_order == expected_order

    assert [67049] == encode_all(["uint32_be"], new_order, [])
    assert [1, 1513] == encode_all(["uint16_be", "uint16_be"], new_order, [])

    binary = <<5, 233, 0, 1>>
    swap_type_list = ["10", "10"]
    new_order = change_bytes_string_order(swap_type_list, binary)
    assert [1513, 1] == encode_all(["uint16_be", "uint16_be"], new_order, [])
  end
end
