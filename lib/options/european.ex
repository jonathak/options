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
  def t(x \\ 40 / 365), do: x

  # granularity of binomial tree (levels)
  def levels(x \\ 5), do: x

  # strike price
  def k(x \\ 40.0), do: x

  # stock price present value
  def s(x \\ 45.0), do: x

  # annual risk free rate continuous compounding
  def r(x \\ 0.05), do: x

  #######################################
  ### start() used during development ###
  #######################################

  def start do
    25..84
    |> Enum.map(&callvalue(&1))
    |> Enum.chunk_every(10)
    |> Enum.map(&avg(&1))
    |> Enum.each(&IO.puts(&1))
  end

  def callvalue(n) do
    dt = dt(t(), n)
    gu = gu(vol(), dt)
    sl = leaves(s(), gu, n)
    cl = cleaves(sl)
    r = r()
    callnode(cl, sl, gu, r, dt) |> hd()
  end

  ###############
  ### library ###
  ###############

  # leaves/3
  # creates the end of the tree
  @doc """
       iex> Options.European.leaves(75.0, 0.8, 6)
       [286.102294921875, 183.10546875000003, 117.18750000000006, 75.00000000000004, 48.00000000000004, 30.720000000000027, 19.660800000000023]
  """
  def leaves(s \\ s(), gu \\ gu(), levels \\ levels()) do
    with gd = gd(gu),
         bottom = s * :math.pow(gd, levels),
         multiplier = gu * gu do
      0..levels
      |> Enum.map(&(bottom * :math.pow(multiplier, &1)))
    end
  end

  # cleaves/2
  # creates the end of the tree
  @doc """
      iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.cleaves(65.0)
      [102.69999999999999, 63.19999999999999, 33.0, 10.0, 0.0, 0.0, 0.0]
  """
  def cleaves(sleaves, k \\ k()) do
    sleaves
    |> Enum.map(&max(&1 - k, 0.0))
  end

  # bondsf/2
  # future value of bonds for hedge
  @doc """
        iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.bondsf([102.7, 63.2, 33.0, 10.0, 0.0, 0.0, 0.0])
        [65.0, 65.00000000000003, 65.0, 57.3, 0.0, 0.0]
  """
  def bondsf(sfl, cfl) do
    sfl
    |> U.pairs()
    |> Enum.zip(U.pairs(cfl))
    |> Enum.map(&bfhelper(&1))
  end

  def bfhelper({[_, _], [x, x]}), do: 0.0
  def bfhelper({[sfu, sfd], [cfu, cfd]}), do: (cfu * sfd - sfu * cfd) / (cfu - cfd)

  # bondsp/3
  # discounted bonds
  @doc """
        iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.bondsp(0.06, 0.50)
        [162.74371597608481, 124.41111740091874, 95.10366228775379, 72.78341501613811, 55.606529072329515, 42.50551436942465, 32.50992537387502]
  """
  def bondsp(bf, r \\ r(), dt \\ dt()) do
    bf |> Enum.map(&(&1 * :math.exp(-r * dt)))
  end

  # htops/2
  # future value(s) of hedged portfolio
  @doc """
        iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.htops([102.7, 63.2, 33.0, 10.0, 0.0, 0.0, 0.0])
        [25.499999999999986, 34.8, 42.0, 47.3, 43.8, 33.5]
  """
  def htops(sfl, bfl) do
    sfl
    |> List.delete_at(0)
    |> Enum.zip(bfl)
    |> Enum.map(&htpshelper(&1))
  end

  def htpshelper({x, y}), do: x - y

  # sfratios/2
  # ratios for adjusting hedged portfolios to call future values
  @doc """
        iex> [25.5, 34.8, 41.9, 47.3, 43.8, 33.5] |> Options.European.sfratios([102.7, 63.2, 33.0, 10.0, 0.0, 0.0, 0.0])
        [0.40348101265822783, 1.0545454545454545, 4.1899999999999995, 0.0, 0.0, 0.0]
  """
  def sfratios(htops, cfl) do
    cfl
    |> List.delete_at(0)
    |> Enum.zip(htops)
    |> Enum.map(&sfrhelper(&1))
  end

  def sfrhelper({0.0, _}), do: 0.0
  def sfrhelper({x, y}), do: y / x

  # callp/3
  # call values back one layer
  @doc """
        iex> [0.6, 0.55, 0.65] |> Options.European.callp([50.0, 100.0, 200.0], [50.0, 100.0, 100.0])
        [0.0, 0.0, 153.84615384615384]
  """
  def callp(hr, sp, bp) do
    Enum.zip([sp, bp, hr])
    |> Enum.map(&cphelper(&1))
  end

  def cphelper({_sp, _bp, 0.0}), do: 0.0
  def cphelper({sp, bp, hr}), do: (sp - bp) / hr

  # callagain/5
  # valuing call prices back one layer
  @doc """
        iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.callagain([102.7, 63.2, 33.0, 10.0, 0.0, 0.0, 0.0], 1.1, 0.04, 0.23)
        [52.140712161874546, 24.686166707329086, 3.7770757982381724, 0.0, 0.0, 0.0]
  """
  def callagain(sf, cf, gu \\ gu(), r \\ r(), dt \\ dt()) do
    with bf = bondsf(sf, cf),
         sp = sf |> sreduce(gd(gu)),
         bp = bf |> bondsp(r, dt) do
      sf
      |> htops(bf)
      |> sfratios(cf)
      |> callp(sp, bp)
    end
  end

  # callnode/5
  # present value of call option
  @doc """
        iex> [0.0, 0.0, 0.0, 14.3, 49.5, 95.5] |> Options.European.callnode([51.1, 66.8, 87.4, 114.3, 149.5, 195.5], 1.14, 0.07, 0.25)
        [17.61075364545998]
  """

  def callnode(cf, sf, gu \\ gu(), r \\ r(), dt \\ dt())

  def callnode(cf, [sfd, sfu], gu, r, dt) do
    with bf = bondsf([sfd, sfu], cf),
         bp = bondsp(bf, r, dt),
         sp = sreduce([sfd, sfu], gd(gu)) do
      [sfd, sfu]
      |> htops(bf)
      |> sfratios(cf)
      |> callp(sp, bp)
    end
  end

  def callnode(cf, sf, gu, r, dt) do
    with sp = sreduce(sf, gd(gu)) do
      callagain(sf, cf, gu, r, dt)
      |> callnode(sp, gu, r, dt)
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

  @doc """
    iex> [1,2,3] |> Options.European.avg()
    2.0
  """
  def avg(x) do
    Enum.reduce(x, fn x, acc -> x + acc end) / length(x)
  end
end
