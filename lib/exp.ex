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

  # Allowed infix operators
  # \\, <-, |, ~>>, <<~, ~>, <~, <~>, <|>, <<<, >>>, |||, &&&, and ^^^.
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

    def p ~>> f do
      bind(p, f)
    end

    def map(p, f) do
      fn cs -> p.(cs) |> Enum.map(fn {c, cs} -> {f.(c), cs} end) end
    end

    def p >>> f do
      map(p, f)
    end

    def zero() do
      fn _ -> [] end
    end

    def and_(p, q) do
      fn cs -> p.(cs) ++ q.(cs) end
    end

    def p <~> q do
      and_(p, q)
    end

    def or_(p, q) do
      fn cs ->
        case and_(p, q).(cs) do
          [] -> []
          [x | _] -> [x]
        end
      end
    end

    def p <|> q do
      or_(p, q)
    end
  end
end
