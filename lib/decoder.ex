defmodule Decoder do
  @external_resource mimes_path = Path.join([__DIR__, "data_types.txt"])

  for line <- File.stream!(mimes_path, [], :line) do
    data_type = String.trim(line)
    str_type = String.replace(data_type, ~r/[\d]/, "") |> String.split(~r/[_]/)
    {d_type, endianess} =
      case str_type do
        [d_type] -> {d_type, :big}
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
        _->
          :integer
      end

    size =
      if data_size != 8 do
        16
      else
        8
      end

    defmacro decode_data_type(unquote(data_type), raw_data, acc) when is_list(raw_data) do
        fn1 =
          cond do
            (unquote(data_size) == 32) or ((unquote(data_size) == 4) and (unquote(d_type) == "ascii")) ->
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
            (unquote(data_size) == 32) ->
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


            ((unquote(data_size) == 2) and (unquote(d_type) == "ascii")) ->
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

            ((unquote(data_size) == 4) and (unquote(d_type) == "ascii")) ->
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
          unquote fn1
          unquote fn2
          acc = unquote(acc) ++ [res]
          {acc, values_tail}
        end

      IO.inspect(fn1)
      IO.inspect(fn2)

      fn_end
    end

    defmacro decode_data_type(unquote(data_type), raw_data, acc) do
      fn1 =
        cond do
          (unquote(data_size) == 32) or ((unquote(data_size) == 4) and (unquote(d_type) == "ascii")) ->
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
          (unquote(data_size) == 32) ->
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


          ((unquote(data_size) == 2) and (unquote(d_type) == "ascii")) ->
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

          ((unquote(data_size) == 4) and (unquote(d_type) == "ascii")) ->
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
        unquote fn1
        unquote fn2
        acc = unquote(acc) ++ [res]
        {acc, values_tail}
      end

    IO.inspect(fn1)
    IO.inspect(fn2)

    fn_end
    end
  end

  defmacro env(raw_data, _acc) do
    fn1 = quote do
      y = unquote raw_data
    end

    # fn2 = quote do
    #   IO.inspect(y)
    # end

    fn2 =
      {{:., [], [{:__aliases__, [alias: false], [:IO]}, :inspect]}, [], [{:y, [], __MODULE__}]}

    fn_end = quote do
      unquote fn1
      unquote fn2
    end

    fn_end
  end

  defmacro say("hola", {:+, _, [arg2, arg1]}, arg3) do
    quote do
      r1 = unquote(arg2) + unquote(arg1)
      r2 = unquote(arg3)
      IO.puts("resultado {#{r1}, #{r2}}")
      {r1, r2}
    end
  end

  defmacro as("hola") do
    {:__block__, [],
      [ #fun1
        {:=, [],
          [
            {:<<>>, [],
            [
              {:::, [],
                [
                  {:uint16_be, [], Elixir},
                  {:-, [context: Elixir, import: Kernel],
                  [
                    {:-, [context: Elixir, import: Kernel],
                      [{:unsigned, [], Elixir}, {:big, [], Elixir}]},
                    {:size, [], [16]}
                  ]}
                ]}
            ]},                     #v1
            {:<<>>, [], [{:::, [], [0x23, {:size, [], [16]}]}]}
          ]},
        #fn2
        {:=, [],
          [
            [{:acc, [], Elixir}],
            {:++, [context: Elixir, import: Kernel],
              #acc
              [[], [{:uint16_be, [], Elixir}]]}
          ]},
        #fn3                #vtail
        {{:acc, [], Elixir}, 0x24}
      ]
    }
  end
end
