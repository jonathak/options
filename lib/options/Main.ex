defmodule Options.Main do
	
  # This start function is primarily for new 
  # function drafting/evaluation/testing, 
  # and will thus change frequently. It is
  # called when evoking "mix start" at CLI.
  import Options.European
  def start() do
    s = spread(1.0, 2)
    c = calldist(s, 1.0)
	combined = bothsandc(s, c)
	IO.inspect combined
    IO.inspect callcalc(combined, 2.0, 0.5, 0.05, 0.33)
  end
end
