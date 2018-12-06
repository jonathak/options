defmodule OptionsTest do
  use ExUnit.Case
  doctest Options
  doctest Options.Main

  test "greets the world" do
    assert Options.hello() == :world
  end
end
