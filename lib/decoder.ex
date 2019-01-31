# TODO:
# add exit functions.

defmodule Decoder do
  @external_resource mimes_path = Path.join([__DIR__, "data_types.txt"])

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro split(bin, n) do
    quote do
      {:<<>>, _, byte_list} = unquote(bin)
      byte_list
        |> Enum.split(unquote(n))
        |> Tuple.to_list()
        |> Enum.map(fn x -> :binary.list_to_bin(x) end)
    end
  end

  def split_def(bin, n) do
    bin
      |> :binary.bin_to_list()
      |> Enum.split(n)
      |> Tuple.to_list()
      |> Enum.map(fn x -> :binary.list_to_bin(x) end)
  end

  for line <- File.stream!(mimes_path, [], :line) do
    data_type = String.trim(line)
    defmacro decode_all(unquote(data_type), raw_data, acc) do
      #parsing data_type_string -> endianess, data_type, sign and size
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

      data_size = String.replace(unquote(data_type) , ~r/[^\d]/, "") |> String.to_integer()

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

        size = div(data_size, 8)

        # quote do
        #   [value, values_tail] = split(unquote(raw_data), unquote (size)
        # end
       [value, values_tail] = split(raw_data, size)
        value = <<0x42,0xcd,0x00,0x00>>
        values_tail = ""
      fn1 =
        cond do
          d_type == "ascii" ->
            if endianess == quote(do: big) do
              quote(do: res = unquote value)
            else
              quote(do: res = unquote String.reverse(value))
            end
          true ->
            quote(do: <<res::unquote(a_type)-unquote(endianess)-unquote(sign)-size(unquote(data_size))>> = unquote(value))
        end

      fn_end =
        quote do
          unquote(fn1)
          acc = unquote(acc) ++ [res]
          {acc, unquote values_tail}
        end
      fn_end
    end
    # def decode(unquote(data_type), raw_data, acc) do
    #   decode_all(unquote(data_type), raw_data, acc)
    # end
  end

  defmacro decode_all(_data_type, _raw_data, _acc) do
    IO.puts("No es valido el tipo de dato (bin)")
  end

  def decode(_data_type, _raw_data, _acc) do
    IO.puts("Invalid Data_type")
    :error
  end
end
