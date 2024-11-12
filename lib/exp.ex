defmodule Exp do
  @moduledoc """
  Documentation for `Exp`.
  """

  # Allowed infix operators
  # \\, <-, |, ~>>, <<~, ~>, <~, <~>, <|>, <<<, >>>, |||, &&&, and ^^^.
  defmodule Parser do
    @doc ~S"""
    Parses a single character.

    ## Example
    iex> import Exp.Parser
    iex> item().("abc")
    [{"a", "bc"}]
    """
    def item() do
      fn
        "" ->
          []

        cs ->
          [String.split_at(cs, 1)]
      end
    end

    @doc ~S"""
    Combinator, returns a parser return `a`.

    ## Example
    iex> import Exp.Parser
    iex> return("a").("bc")
    [{"a", "bc"}]
    """
    def return(a) do
      fn cs -> [{a, cs}] end
    end

    @doc ~S"""
    Combinator to transform a parser `p` by applying `f`.
    `f` has to return a new parser.

    ## Example
    iex> import Exp.Parser
    iex> bind(item(), fn c -> return("#{c}ba") end).("abc")
    [{"aba", "bc"}]
    """
    def bind(p, f) do
      fn cs -> p.(cs) |> Enum.flat_map(fn {a, cs} -> f.(a).(cs) end) end
    end

    @doc ~S"""
    Combinator, infix variant of `bind`.

    ## Example
    iex> import Exp.Parser
    iex> item() ~>> fn c -> return("#{c}ba") end.("abc")
    """
    def p ~>> f do
      bind(p, f)
    end

    @doc ~S"""
    Combinator to transform parser `p` by appluing `f`.

    ## Example
    iex> import Exp.Parser
    iex> map(item(), fn c -> "#{c}bc" end).("abc")
    [{"abc", "bc"}]
    """
    def map(p, f) do
      fn cs -> p.(cs) |> Enum.map(fn {c, cs} -> {f.(c), cs} end) end
    end

    @doc ~S"""
    Combinator, infxi variant of `map`.

    ## Example
    iex> import Exp.Parser
    iex> (item() >>> fn c -> "#{c}bc" end).("abc")
    [{"abc", "bc"}]
    """
    def p >>> f do
      map(p, f)
    end

    @doc ~S"""
    Create a failed parser.

    ## Example
    iex> import Exp.Parser
    iex> (zero() >>> fn x -> "#{x}bc" end).("abc")
    []
    """
    def zero() do
      fn _ -> [] end
    end

    @doc ~S"""
    Combinator, uses `p` and `q` to parse the input, both outputs are collected into the output list.

    ## Example
    iex> import Exp.Parser
    iex> and_(item(), return("d")).("abc")
    [{"a", "bc"}, {"d","abc"}]
    """
    def and_(p, q) do
      fn cs -> p.(cs) ++ q.(cs) end
    end

    @doc ~S"""
    Combinator, infix variant of `and_`.

    ## Example
    iex> import Exp.Parser
    iex> (item() &&& return("d")).("abc")
    [{"a", "bc"}, {"d","abc"}]
    """
    def p &&& q do
      and_(p, q)
    end

    @doc ~S"""
    Combinator, uses `p` to parse the input, if `p` fails `q` is used to parse the input.

    ## Example
    iex> import Exp.Parser
    iex> or_(zero(), return("d")).("abc")
    [{"d","abc"}]
    """
    def or_(p, q) do
      fn cs ->
        case p.(cs) do
          [] -> q.(cs)
          r -> r
        end
      end
    end

    @doc ~S"""
    Combinator, infix variant of `or_`.

    ## Example
    iex> import Exp.Parser
    iex> (zero() ||| return("d")).("abc")
    [{"d","abc"}]
    """
    def p ||| q do
      or_(p, q)
    end

    @doc ~S"""
    Creates a parser that parses input that statisfies the predicate `p`.

    ## Example
    iex> import Exp.Parser
    iex> sat(fn c -> c == "a" end).("abc")
    [{"a","bc"}]
    """
    def sat(p) do
      item()
      ~>> fn c ->
        if p.(c) do
          return(c)
        else
          zero()
        end
      end
    end

    @doc ~S"""
    Creates a parser that parses the given charactet `c`.

    ## Example
    iex> import Exp.Parser
    iex> char("a").("abc")
    [{"a","bc"}]
    """
    def char(c) do
      sat(fn c2 -> c == c2 end)
    end

    def string("") do
      return("")
    end

    @doc ~S"""
    Creates a parser that parses the given string `s`.

    ## Example
    iex> import Exp.Parser
    iex> string("ab").("abc")
    [{"ab","c"}]
    """
    def string(s) do
      [c | cs] = String.split_at(s, 1)
      char(c) ~>> fn _ -> string(cs) end ~>> fn _ -> return(s) end
    end

    def many(p) do
      many1(p) ||| return([])
    end

    def many1(p) do
      fn cs ->
        p.(cs) ~>> fn a -> many(p) ~>> fn as -> return([a | as]) end end
      end
    end

    def sepby(p, p_sep) do
      sepby1(p, p_sep) ||| return([])
    end

    def sepby1(p, p_sep) do
      fn cs ->
        p.(cs) ~>> fn a -> many(p_sep ~>> fn _ -> p.() end) ~>> fn as -> return([a | as]) end end
      end
    end

    def chain(p, op, a) do
      chain1(p, op) ||| return(a)
    end

    def chain1(p, op) do
      fn cs ->
        p.(cs) ~>> fn a -> rest(p, op, a) end
      end
    end

    defp rest(p, op, a) do
      fn cs ->
        op.(cs) ~>> fn f -> p.() ~>> fn b -> rest(p, op, f.(a, b)) ||| return(a) end end
      end
    end
  end
end
