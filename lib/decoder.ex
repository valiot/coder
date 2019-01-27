defmodule Decoder do
  @external_resource mimes_path = Path.join([__DIR__, "data_types.txt"])
  for line <- File.stream!(mimes_path, [], :line) do
    data_type = String.trim(line)
    [d_type, endianess] =
      String.replace(data_type, ~r/[\d]/, "") |> String.split(~r/[_]/)
    data_size = String.replace(data_type, ~r/[^\d]/, "") |> String.to_integer()
    expression =
    quote do
      IO.puts("d_type = #{unquote d_type}")
      IO.puts("endianess = #{unquote endianess}")
      IO.puts("data_size = #{unquote data_size}")
    end

    def decode_data_type(unquote(data_type)), do: unquote(expression)
    #def type_from_ext(ext) when ext in unquote(expresions), do: unquote(data_type)


  end

  defmacro say("hola",{:+, _, [arg2, arg1]}) do
    quote do
      r1 = unquote(arg2) + unquote(arg1)
      IO.puts("resultado {#{r1}")
      {r1}
    end
  end



  # def exts_from_type(_type), do: []
  # def type_from_ext(_ext), do: nil
  # def valid_type?(type), do: exts_from_type(type) |> Enum.any?
end
