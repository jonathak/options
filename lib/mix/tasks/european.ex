defmodule Mix.Tasks.European do
  use Mix.Task

  def run(params) do
    try do
      ps = params
      pp = ps |> Enum.map(&convhelper(&1))
      [s, k, v, t, r, n] = pp
      Options.European.start(s, k, v, t, r, trunc(n))
    rescue
      _ -> IO.puts("Usage: mix european s ex v t r n")
    end
  end

  def convhelper(x) do
    try do
      String.to_float(x)
    rescue
      _ -> String.to_integer(x)
    end
  end
end
