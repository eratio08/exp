defmodule Exp do
  @moduledoc """
  Documentation for `Exp`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Exp.hello()
      :world

  """
  def hello do
    :world
  end

  defmodule Parser do
    def item() do
      fn
        "" ->
          []

        cs ->
          [String.split_at(cs, 1)]
      end
    end

    def return(a) do
      fn cs -> [{a, cs}] end
    end

    def bind(p, f) do
      fn cs -> p.(cs) |> Enum.flat_map(fn {c, cs} -> [{f.(c), cs}] end) end
    end

    def map(p, f) do
      fn cs -> p.(cs) |> Enum.map(fn {c, cs} -> {f.(c), cs} end) end
    end
  end
end
