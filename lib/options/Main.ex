defmodule Options.Main do
	
  # This start function is primarily for new 
  # function drafting/evaluation/testing, 
  # and will thus change frequently. It is
  # called when evoking "mix start" at CLI.
  import Options.European
  def start() do
    s = spread(1.0, 2)
    c = calldist(s, 1.0)
	combine = bothsandc(s, c)
	h = combine |> hd()
	IO.inspect h
  end
end
