defmodule Mix.Tasks.Start do
  use Mix.Task

  def run(_), do: Options.Main.start
end