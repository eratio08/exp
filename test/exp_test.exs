defmodule ExpTest do
  use ExUnit.Case
  doctest Exp

  test "greets the world" do
    assert Exp.hello() == :world
  end
end
