defmodule Options.Main do
	
  # This start function is primarily for new 
  # function drafting/evaluation/testing, 
  # and will thus change frequently. It is
  # called when evoking "mix start" at CLI.
  def start() do
	  # def simplecall(sp, levels, t, vol, ex, r)
		IO.inspect Options.European.simplecall(100.0, 15, 1.0, 0.2, 100.0, 0.05)
		#IO.inspect Options.European.spread(100, 3, :math.exp(0.1*:math.sqrt(3)), :math.exp(-0.1*:math.sqrt(3)))
  end
end
