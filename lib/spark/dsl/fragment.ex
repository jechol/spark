defmodule Spark.Dsl.Fragment do
  defmacro __using__(opts) do
    opts = Macro.expand_literals(opts, __CALLER__)
    single_extension_kinds = opts[:of].single_extension_kinds()
    many_extension_kinds = opts[:of].many_extension_kinds()

    {_, extensions} =
      opts[:of].default_extension_kinds()
      |> Enum.reduce(opts, fn {key, defaults}, opts ->
        Keyword.update(opts, key, defaults, fn current_value ->
          cond do
            key in single_extension_kinds ->
              current_value || defaults

            key in many_extension_kinds || key == :extensions ->
              List.wrap(current_value) ++ List.wrap(defaults)

            true ->
              current_value
          end
        end)
      end)
      |> Spark.Dsl.expand_modules(
        [
          single_extension_kinds: single_extension_kinds,
          many_extension_kinds: many_extension_kinds
        ],
        __CALLER__
      )

    Module.register_attribute(__CALLER__.module, :spark_extension_kinds, persist: true)
    Module.register_attribute(__CALLER__.module, :spark_fragment_of, persist: true)

    Module.put_attribute(__CALLER__.module, :spark_fragment_of, opts[:of])
    Module.put_attribute(__CALLER__.module, :extensions, extensions)

    Module.put_attribute(
      __CALLER__.module,
      :spark_extension_kinds,
      List.wrap(many_extension_kinds) ++
        List.wrap(single_extension_kinds)
    )

    quote do
      require unquote(opts[:of])
      unquote(Spark.Dsl.Extension.prepare(extensions))
      @before_compile Spark.Dsl.Fragment
    end
  end

  defmacro __before_compile__(_) do
    quote do
      Spark.Dsl.Extension.set_state([], false)

      def extensions do
        @extensions
      end

      def spark_dsl_config do
        @spark_dsl_config
      end
    end
  end
end
