defmodule Options.European do
  alias Options.Utils, as: U

  @moduledoc """
  Functions for evaluating European call options.
  """

  ######################
  ### default values ###
  ######################

  # volatility
  def vol(x \\ 0.3), do: x

  # time to maturity (years)
  def t(x \\ 40.0/365), do: x

  # granularity of binomial tree (levels)
  def levels(x \\ 5), do: x

  # strike price
  def k(x \\ 50.0), do: x

  # stock price present value
  def s(x \\ 30.0), do: x

  # annual risk free rate continuous compounding
  def r(x \\ 0.05), do: x

  #######################################
  ### start() used during development ###
  #######################################

  
	def start do
		(1..50) |> Enum.map(&callvalue(&1))
	end
	
	def callvalue(n) do
    sl = leaves(s(), gu(), n)
    cl = cleaves(sl)
    IO.puts "#{hd(callnode(sl, cl))}"
  end

  ###############
  ### library ###
  ###############

  # leaves/3
  # creates the end of the tree
  @doc """
      iex> Options.European.leaves(100.0, 0.8744465748183686, 5)
      [51.128894767778185, 66.86515303499456, 87.44465748183684, 114.35804413868394, 149.55473136756888, 195.58412215673536]
  """
  def leaves(s \\ s(), gu \\ gu(), levels \\ levels()) do
    with gd = gd(gu),
         bottom = s * :math.pow(gd, levels),
         multiplier = gu * gu do
      0..levels
      |> Enum.map(&(bottom * :math.pow(multiplier, &1)))
    end
  end

  def cleaves(sleaves, k \\ k()) do
    sleaves
    |> Enum.map(&max(&1 - k, 0.0))
  end

  def bondsf(sfl, cfl) do
    with sfchomp = sfl |> List.delete_at(-1),
         cfchomp = cfl |> List.delete_at(-1),
         combined = Enum.zip([sfchomp, cfchomp]) do
      combined |> Enum.map(&(elem(&1, 0) - elem(&1, 1)))
    end
  end

  def bondsp(bf, r \\ r(), dt \\ dt()) do
    bf |> Enum.map(&(&1 * :math.exp(-r * dt)))
  end

  def htops(sfl, bfl) do
    with stops = sfl |> List.delete_at(0),
         combined = Enum.zip([stops, bfl]) do
      combined |> Enum.map(&(elem(&1, 0) - elem(&1, 1)))
    end
  end

  def sfratios(htops, cfl) do
    with ctops = cfl |> List.delete_at(0),
         combined = Enum.zip([htops, ctops]) do
      combined |> Enum.map(&sfrhelper(&1))
    end
  end

  def sfrhelper({_x, 0.0}), do: 0.0
  def sfrhelper({x, y}), do: x / y

  def callp(sp, bp, hr) do
    with combined = Enum.zip([sp, bp, hr]) do
      combined |> Enum.map(&cphelper(&1))
    end
  end

  def cphelper({_sp, _bp, 0.0}), do: 0.0
  def cphelper({sp, bp, hr}), do: (sp - bp) / hr

  def callagain(sf, cf, gu \\ gu(), r \\ r(), dt \\ dt()) do
    with gd = gd(gu),
         sp = sreduce(sf, gd),
         bf = bondsf(sf, cf),
         bp = bondsp(bf, r, dt),
         ht = htops(sf, bf),
         hr = sfratios(ht, cf) do
      callp(sp, bp, hr)
    end
  end

  def callnode(sf, cf, gu \\ gu(), r \\ r(), dt \\ dt()) do
    with gd = gd(gu),
         sp = sreduce(sf, gd),
         bf = bondsf(sf, cf),
         bp = bondsp(bf, r, dt),
         ht = htops(sf, bf),
         hr = sfratios(ht, cf) do
      if length(sf) == 2 do
        callp(sp, bp, hr)
      else
        cp = callagain(sf, cf, gu, r, dt)
        callnode(sp, cp, gu, r, dt)
      end
    end
  end

  # dt/2
  # duration of time step given number of levels and time to maturity
  @doc """
      iex> Options.European.dt(1.0, 5)
      0.2
  """
  def dt(t \\ t(), l \\ levels()) do
    t / l
  end

  # gu/2
  # up growth rate given volatility and duration of time step
  @doc """
      iex> Options.European.gu(0.3, 0.2)
      1.1435804413868396
  """
  def gu(v \\ vol(), dt \\ dt()) do
    U.voltorate(v, dt)
  end

  # gd/1
  # down growth rate given up growth rate for symetric tree
  @doc """
      iex> Options.European.gd(2.0)
      0.5
  """
  def gd(gu \\ gu()) do
    1.0 / gu
  end

  # reduce/2
  # steps stock price list down binomial tree by single layer
  @doc """
      iex> [0.25, 1.0, 4.0] |> Options.European.sreduce(0.5)
      [0.5, 2.0]
  """
  def sreduce(slist, gd \\ gd()) do
    slist
    |> List.delete_at(0)
    |> Enum.map(&(&1 * gd))
  end

  # clist/2
  # provides call option values at end of binomial tree
  @doc """
      iex> [0.25, 1.0, 4.0] |> Options.European.clist(0.5)
      [0.0, 0.5, 3.5]
  """
  def clist(slist, k \\ k()) do
    slist
    |> Enum.map(&max(0.0, &1 - k))
  end
end
