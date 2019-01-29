# TODO:
# add __using__ macro
# change ast -> functions
# add exit functions.

defmodule Decoder do
  @external_resource mimes_path = Path.join([__DIR__, "data_types.txt"])

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  for line <- File.stream!(mimes_path, [], :line) do
    data_type = String.trim(line)
    str_type = String.replace(data_type, ~r/[\d]/, "") |> String.split(~r/[_]/)

    {d_type, endianess} =
      case str_type do
        [d_type] ->
          {d_type, :big}

        [d_type, endianess] ->
          if endianess == "be" do
            {d_type, :big}
          else
            {d_type, :little}
          end
      end

    data_size = String.replace(data_type, ~r/[^\d]/, "") |> String.to_integer()

    sign =
      if String.starts_with?(d_type, "u") do
        :unsigned
      else
        :signed
      end

    a_type =
      case d_type do
        "float" ->
          :float

        _ ->
          :integer
      end

    size =
      if data_size != 8 do
        16
      else
        8
      end

    defmacro decode_data_type_l(unquote(data_type), raw_data, acc) do
      fn1 =
        cond do
          unquote(data_size) == 32 or (unquote(data_size) == 4 and unquote(d_type) == "ascii") ->
            {:=, [],
             [
               [
                 {:value_1, [], __MODULE__},
                 {:|, [], [{:value_2, [], __MODULE__}, {:values_tail, [], __MODULE__}]}
               ],
               raw_data
             ]}

          true ->
            {:=, [],
             [
               [{:|, [], [{:value, [], __MODULE__}, {:values_tail, [], __MODULE__}]}],
               raw_data
             ]}
        end

      fn2 =
        cond do
          unquote(data_size) == 32 ->
            {:=, [],
             [
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:res, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [
                        {:-, [context: __MODULE__, import: Kernel],
                         [
                           {:-, [context: __MODULE__, import: Kernel],
                            [{unquote(a_type), [], __MODULE__}, {unquote(sign), [], __MODULE__}]},
                           {unquote(endianess), [], __MODULE__}
                         ]},
                        {:size, [], [unquote(data_size)]}
                      ]}
                   ]}
                ]},
               {:<<>>, [],
                [
                  {:::, [], [{:value_1, [], __MODULE__}, {:size, [], [unquote(size)]}]},
                  {:::, [], [{:value_2, [], __MODULE__}, {:size, [], [unquote(size)]}]}
                ]}
             ]}

          unquote(data_size) == 2 and unquote(d_type) == "ascii" ->
            {:=, [],
             [
               {:res, [], __MODULE__},
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:value, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [{unquote(endianess), [], __MODULE__}, {:size, [], [unquote(size)]}]}
                   ]}
                ]}
             ]}

          unquote(data_size) == 4 and unquote(d_type) == "ascii" ->
            {:=, [],
             [
               {:res, [], __MODULE__},
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:value_1, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [{unquote(endianess), [], Elixir}, {:size, [], [unquote(size)]}]}
                   ]},
                  {:::, [],
                   [
                     {:value_2, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [{unquote(endianess), [], __MODULE__}, {:size, [], [unquote(size)]}]}
                   ]}
                ]}
             ]}

          true ->
            {:=, [],
             [
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:res, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [
                        {:-, [context: __MODULE__, import: Kernel],
                         [
                           {:-, [context: __MODULE__, import: Kernel],
                            [{unquote(a_type), [], __MODULE__}, {unquote(sign), [], __MODULE__}]},
                           {unquote(endianess), [], __MODULE__}
                         ]},
                        {:size, [], [unquote(size)]}
                      ]}
                   ]}
                ]},
               {:<<>>, [], [{:::, [], [{:value, [], __MODULE__}, {:size, [], [unquote(size)]}]}]}
             ]}
        end

      fn_end =
        quote do
          unquote(fn1)
          unquote(fn2)
          acc = unquote(acc) ++ [res]
          {acc, values_tail}
        end

      fn_end
    end

    defmacro decode_data_type(unquote(data_type), raw_data, acc) do
      fn1 =
        cond do
          unquote(data_size) == 32 or (unquote(data_size) == 4 and unquote(d_type) == "ascii") ->
            {:=, [],
             [
               {:<<>>, [],
                [
                  {:::, [], [{:value_1, [], __MODULE__}, {:size, [], [unquote(size)]}]},
                  {:::, [], [{:value_2, [], __MODULE__}, {:size, [], [unquote(size)]}]},
                  {:::, [], [{:values_tail, [], __MODULE__}, {:binary, [], __MODULE__}]}
                ]},
               raw_data
             ]}

          true ->
            {:=, [],
             [
               {:<<>>, [],
                [
                  {:::, [], [{:value, [], __MODULE__}, {:size, [], [unquote(size)]}]},
                  {:::, [], [{:values_tail, [], __MODULE__}, {:binary, [], __MODULE__}]}
                ]},
               raw_data
             ]}
        end

      fn2 =
        cond do
          unquote(data_size) == 32 ->
            {:=, [],
             [
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:res, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [
                        {:-, [context: __MODULE__, import: Kernel],
                         [
                           {:-, [context: __MODULE__, import: Kernel],
                            [{unquote(a_type), [], __MODULE__}, {unquote(sign), [], __MODULE__}]},
                           {unquote(endianess), [], __MODULE__}
                         ]},
                        {:size, [], [unquote(data_size)]}
                      ]}
                   ]}
                ]},
               {:<<>>, [],
                [
                  {:::, [], [{:value_1, [], __MODULE__}, {:size, [], [unquote(size)]}]},
                  {:::, [], [{:value_2, [], __MODULE__}, {:size, [], [unquote(size)]}]}
                ]}
             ]}

          unquote(data_size) == 2 and unquote(d_type) == "ascii" ->
            {:=, [],
             [
               {:res, [], __MODULE__},
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:value, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [{unquote(endianess), [], __MODULE__}, {:size, [], [unquote(size)]}]}
                   ]}
                ]}
             ]}

          unquote(data_size) == 4 and unquote(d_type) == "ascii" ->
            {:=, [],
             [
               {:res, [], __MODULE__},
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:value_1, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [{unquote(endianess), [], Elixir}, {:size, [], [unquote(size)]}]}
                   ]},
                  {:::, [],
                   [
                     {:value_2, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [{unquote(endianess), [], __MODULE__}, {:size, [], [unquote(size)]}]}
                   ]}
                ]}
             ]}

          true ->
            {:=, [],
             [
               {:<<>>, [],
                [
                  {:::, [],
                   [
                     {:res, [], __MODULE__},
                     {:-, [context: __MODULE__, import: Kernel],
                      [
                        {:-, [context: __MODULE__, import: Kernel],
                         [
                           {:-, [context: __MODULE__, import: Kernel],
                            [{unquote(a_type), [], __MODULE__}, {unquote(sign), [], __MODULE__}]},
                           {unquote(endianess), [], __MODULE__}
                         ]},
                        {:size, [], [unquote(size)]}
                      ]}
                   ]}
                ]},
               {:<<>>, [], [{:::, [], [{:value, [], __MODULE__}, {:size, [], [unquote(size)]}]}]}
             ]}
        end

      fn_end =
        quote do
          unquote(fn1)
          unquote(fn2)
          acc = unquote(acc) ++ [res]
          {acc, values_tail}
        end

      fn_end
    end

    def decode(unquote(data_type), raw_data, acc) when is_list(raw_data),
      do: decode_data_type_l(unquote(data_type), raw_data, acc)

    def decode(unquote(data_type), raw_data, acc),
      do: decode_data_type(unquote(data_type), raw_data, acc)
  end

  defmacro decode_data_type(_data_type, raw_data, _acc) when is_list(raw_data) do
    IO.puts("No es valido el tipo de dato (lista)")
  end

  defmacro decode_data_type(_data_type, _raw_data, _acc) do
    IO.puts("No es valido el tipo de dato (bin)")
  end

  def decode(_data_type, _raw_data, _acc) do
    IO.puts("Invalid Data_type")
    :error
  end
end
