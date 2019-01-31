defmodule Decoder do
  @external_resource mimes_path = Path.join([__DIR__, "data_types.txt"])

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  for line <- File.stream!(mimes_path, [], :line) do
    data_type = String.trim(line)

    defmacro decode_all(unquote(data_type), raw_data, acc) do
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

      # decoding function
      fn1 =
        quote do
          size = div(unquote(data_size), 8)

          [value, values_tail] =
            unquote(raw_data)
            |> :binary.bin_to_list()
            |> Enum.split(size)
            |> Tuple.to_list()
            |> Enum.map(fn x -> :binary.list_to_bin(x) end)

          decode_value =
            cond do
              unquote(d_type) == "ascii" ->
                if unquote(str_endian) == "be" do
                  value
                else
                  String.reverse(value)
                end

              true ->
                <<res::unquote(a_type)-unquote(endianess)-unquote(sign)-size(unquote(data_size))>> =
                  value

                res
            end

          acc = unquote(acc) ++ [decode_value]
          {acc, values_tail}
        end

      fn1
    end

    def decode(unquote(data_type), raw_data, acc),
      do: decode_all(unquote(data_type), raw_data, acc)
  end

  defmacro decode_all(_data_type, _raw_data, _acc) do
    IO.puts("No es valido el tipo de dato (bin)")
  end

  def decode(_data_type, _raw_data, _acc) do
    IO.puts("Invalid Data_type")
    :error
  end
end
