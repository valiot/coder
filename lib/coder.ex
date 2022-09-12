# todo: add encode_split(unquote(data_type), value)
defmodule Coder do
  @external_resource mimes_path = Path.join([__DIR__, "data_types.txt"])
  @moduledoc """
  A module to encode raw bitstring into standard data_type (look at data_types.txt)
  """
  require Logger

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  for line <- File.stream!(mimes_path, [], :line) do
    data_type = String.trim(line)

    defmacro encode_spec(unquote(data_type), raw_data) do
      # parsing data_type_string -> endianess, data_type, sign and size
      str_type = String.replace(unquote(data_type), ~r/[\d]/, "") |> String.split(~r/[_]/)

      {d_type, endianess, str_endian} =
        case str_type do
          [d_type] ->
            {d_type, quote(do: big), nil}

          [d_type, str_endianess] ->
            if str_endianess == "be" do
              {d_type, quote(do: big), "be"}
            else
              {d_type, quote(do: little), "le"}
            end
        end

      data_size = String.replace(unquote(data_type), ~r/[^\d]/, "") |> String.to_integer()

      sign =
        if String.starts_with?(d_type, "u") do
          quote(do: unsigned)
        else
          quote(do: signed)
        end

      a_type =
        case d_type do
          "float" ->
            quote(do: float)

          _ ->
            quote(do: integer)
        end

      # decoding functions
      fn1 =
        quote do
          size = div(unquote(data_size), 8)

          [value, values_tail] =
            unquote(raw_data)
            |> :binary.bin_to_list()
            |> Enum.split(size)
            |> Tuple.to_list()
            |> Enum.map(fn x -> :binary.list_to_bin(x) end)

          encode_value =
            case unquote(d_type) do
              "ascii" ->
                if unquote(str_endian) == "be" do
                  value
                else
                  value
                  |> :binary.bin_to_list()
                  |> Enum.reverse()
                  |> :binary.list_to_bin()
                end

              _ ->
                try do
                  <<res::unquote(a_type)-unquote(endianess)-unquote(sign)-size(unquote(data_size))>> =
                    value

                  res
                rescue
                  _ ->
                    "null"
                end
            end

          {encode_value, values_tail}
        end

      fn1
    end

    defmacro decode_spec(unquote(data_type), raw_data) do
      # parsing data_type_string -> endianess, data_type, sign and size
      str_type = String.replace(unquote(data_type), ~r/[\d]/, "") |> String.split(~r/[_]/)

      {d_type, endianess} =
        case str_type do
          [d_type] ->
            {d_type, quote(do: big)}

          [d_type, str_endianess] ->
            if str_endianess == "be" do
              {d_type, quote(do: big)}
            else
              {d_type, quote(do: little)}
            end
        end

      data_size = String.replace(unquote(data_type), ~r/[^\d]/, "") |> String.to_integer()

      sign =
        if String.starts_with?(d_type, "u") do
          quote(do: unsigned)
        else
          quote(do: signed)
        end

      {a_type, raw_data} =
        case d_type do
          "float" ->
            {quote(do: float), raw_data}

          _ ->
            {quote(do: integer), quote(do: round(unquote(raw_data)))}
        end

      # decoding functions
      quote do
        <<unquote(raw_data)::unquote(a_type)-unquote(endianess)-unquote(sign)-size(
            unquote(data_size)
          )>>
      end
    end

    def decode(unquote(data_type), raw_data),
      do: decode_spec(unquote(data_type), raw_data)

    def encode(unquote(data_type), raw_data),
      do: encode_spec(unquote(data_type), raw_data)
  end

  defmacro encode_spec(data_type, _raw_data) do
    IO.puts("\"#{data_type}\" not supported")
  end

  @doc """
  Encodes a binary `raw_data` according to "data_type" specification.
  """
  @spec encode(binary(), binary()) :: {binary(), binary()} | :error
  def encode(data_type, _raw_data) do
    IO.puts("\"#{data_type}\" not supported")
    :error
  end

  @doc """
  Encodes a `raw_list` of bitstrings (in which each elements has `n_bits`) to the corresponding
  data_type in `data_type_list` list.
  """
  def encode_list(data_type_list, raw_list, n_bits)
      when is_list(raw_list) and is_list(data_type_list) do
    raw_data = list_to_binary(raw_list, n_bits, <<>>)
    encode_all(data_type_list, raw_data, [])
  end

  @doc """
  Encodes a raw bitstring to the corresponding data_type in `data_type_list` list.
  """
  def encode_all([], "", acc), do: acc
  def encode_all(_data_type, "", _acc), do: :badargs
  def encode_all([], _value, _acc), do: :badargs

  def encode_all([actual_type | tail], values, acc) when is_bitstring(values) do
    {value, rest} = encode(actual_type, values)
    acc = acc ++ [value]
    encode_all(tail, rest, acc)
  end

  def binary_to_list(<<>>, acc), do: acc
  def binary_to_list(<<bin>>, acc), do: acc ++ [bin]

  def binary_to_list(<<byte1, byte2>> <> tail, acc) do
    <<word::size(16)>> = <<byte1, byte2>>
    acc = acc ++ [word]
    binary_to_list(tail, acc)
  end

  def list_to_binary([], _n_bytes, acc), do: acc

  def list_to_binary(_raw_list, n_bytes, _acc) when rem(n_bytes, 8) != 0,
    do: IO.puts("Error in lists element size")

  def list_to_binary([value | tail] = raw_list, n_bits, acc) when is_list(raw_list) do
    bytes = <<value::size(n_bits)>>
    acc = acc <> bytes
    list_to_binary(tail, n_bits, acc)
  end

  def change_bytes_order("0", <<b0>>), do: <<b0>>

  def change_bytes_order("10", <<b1, b0>>), do: <<b1, b0>>
  def change_bytes_order("01", <<b1, b0>>), do: <<b0, b1>>

  def change_bytes_order(swap_type, <<_b1, _b0>>),
    do: raise("Unsupported bytes order change: #{swap_type} for two bytes.")

  def change_bytes_order(swap_type, <<_b1, _b0, _rest::binary>>) when swap_type in ["10", "01"],
    do:
      raise(
        "The Swap type \"10\" and \"01\" are only for binaries with only two bytes (<<byte1, byte0>>)."
      )

  def change_bytes_order("0123", <<b3, b2, b1, b0>>), do: <<b0, b1, b2, b3>>
  def change_bytes_order("0132", <<b3, b2, b1, b0>>), do: <<b0, b1, b3, b2>>
  def change_bytes_order("0213", <<b3, b2, b1, b0>>), do: <<b0, b2, b1, b3>>
  def change_bytes_order("0231", <<b3, b2, b1, b0>>), do: <<b0, b2, b3, b1>>
  def change_bytes_order("0312", <<b3, b2, b1, b0>>), do: <<b0, b3, b1, b2>>
  def change_bytes_order("0321", <<b3, b2, b1, b0>>), do: <<b0, b3, b2, b1>>

  def change_bytes_order("1023", <<b3, b2, b1, b0>>), do: <<b1, b0, b2, b3>>
  def change_bytes_order("1032", <<b3, b2, b1, b0>>), do: <<b1, b0, b3, b2>>
  def change_bytes_order("1203", <<b3, b2, b1, b0>>), do: <<b1, b2, b0, b3>>
  def change_bytes_order("1230", <<b3, b2, b1, b0>>), do: <<b1, b2, b3, b0>>
  def change_bytes_order("1302", <<b3, b2, b1, b0>>), do: <<b1, b3, b0, b2>>
  def change_bytes_order("1320", <<b3, b2, b1, b0>>), do: <<b1, b3, b2, b0>>

  def change_bytes_order("2013", <<b3, b2, b1, b0>>), do: <<b2, b0, b1, b3>>
  def change_bytes_order("2031", <<b3, b2, b1, b0>>), do: <<b2, b0, b3, b1>>
  def change_bytes_order("2103", <<b3, b2, b1, b0>>), do: <<b2, b1, b0, b3>>
  def change_bytes_order("2130", <<b3, b2, b1, b0>>), do: <<b2, b1, b3, b0>>
  def change_bytes_order("2301", <<b3, b2, b1, b0>>), do: <<b2, b3, b0, b1>>
  def change_bytes_order("2310", <<b3, b2, b1, b0>>), do: <<b2, b3, b1, b0>>

  def change_bytes_order("3012", <<b3, b2, b1, b0>>), do: <<b3, b0, b1, b2>>
  def change_bytes_order("3021", <<b3, b2, b1, b0>>), do: <<b3, b0, b2, b1>>
  def change_bytes_order("3102", <<b3, b2, b1, b0>>), do: <<b3, b1, b0, b2>>
  def change_bytes_order("3120", <<b3, b2, b1, b0>>), do: <<b3, b1, b2, b0>>
  def change_bytes_order("3201", <<b3, b2, b1, b0>>), do: <<b3, b2, b0, b1>>
  def change_bytes_order("3210", <<b3, b2, b1, b0>>), do: <<b3, b2, b1, b0>>

  def change_bytes_order(swap_type, <<_b3, _b2, _b1, _b0>>),
    do: raise("Unsupported bytes order change: #{swap_type}")

  def change_bytes_order(_swap_type, <<_b3, _b2, _b1, _b0, _rest::binary>>),
    do:
      raise(
        "The Swap types are only for binaries with only four bytes (<<byte3, byte2, byte1, byte0>>)."
      )

  def change_bytes_order(swap_type, binary),
    do: raise("Incompatible Swap: #{swap_type} -> #{binary}")

  def change_bytes_string_order(swap_type_list, binary) do
    {new_binary, _remainders} =
      for swap_type <- swap_type_list, reduce: {<<>>, binary} do
        {acc, binary_rest} ->
          n_bytes = String.length(swap_type)
          {current_bytes, new_rest, _position} = split_binary_at(binary_rest, n_bytes)
          {acc <> change_bytes_order(swap_type, current_bytes), new_rest}
      end

    new_binary
  end

  def split_binary_at(bitstring, position) do
    for <<binary <- bitstring>>, reduce: {<<>>, <<>>, 1} do
      {before_position, after_postion, current_position} ->
        {before_position, after_postion} =
          if current_position <= position,
            do: {before_position <> <<binary>>, after_postion},
            else: {before_position, after_postion <> <<binary>>}

        {before_position, after_postion, current_position + 1}
    end
  end
end
