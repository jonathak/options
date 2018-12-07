defmodule Options.Main do
	
  # This start function is primarily for new 
  # function drafting/evaluation/testing, 
  # and will thus change frequently. It is
  # called when evoking "mix start" at CLI.
  def start() do
	  # def simplecall(sp, levels, dt, gu, gd, ex, r)
	  IO.inspect Options.European.simplecall(100.0, 2, 1.0, 1.5, 0.5, 100.0, 0.00)
  end
end
