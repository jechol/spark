defmodule Spark.ModulePathPolicyTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defp env, do: __ENV__

  defp alias_ast(parts), do: {:__aliases__, [alias: false], parts}

  defp fetch(ast, path), do: Enum.reduce(path, ast, &Keyword.fetch!(&2, &1))

  describe "expand_module_paths/5" do
    test "경로에 지정한 alias만 policy를 받고 나머지 alias는 그대로 둔다" do
      value = [
        instance_of: alias_ast([:MyApp, :Invoice]),
        fields: [amount: [type: alias_ast([:MyApp, :MoneyType])]]
      ]

      result =
        Extension.expand_module_paths(
          value,
          :constraints,
          [],
          [[:constraints, :instance_of]],
          env()
        )

      assert is_atom(fetch(result, [:instance_of]))
      assert alias_ast([:MyApp, :MoneyType]) == fetch(result, [:fields, :amount, :type])
    end

    test "atom 원소는 경로 처리에서 무시된다" do
      value = [instance_of: alias_ast([:MyApp, :Invoice])]

      assert value == Extension.expand_module_paths(value, :constraints, [], [:change], env())
    end

    test "다른 field의 경로는 적용되지 않는다" do
      value = [instance_of: alias_ast([:MyApp, :Invoice])]

      assert value ==
               Extension.expand_module_paths(
                 value,
                 :other_field,
                 [],
                 [[:constraints, :instance_of]],
                 env()
               )
    end

    test "keyword list literal이 아니면 탐색하지 않는다" do
      value = quote(do: build_constraints())

      assert value ==
               Extension.expand_module_paths(
                 value,
                 :constraints,
                 [],
                 [[:constraints, :instance_of]],
                 env()
               )
    end
  end
end
