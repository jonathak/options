defmodule Options.European do
  @moduledoc """
  Functions for evaluating European call options.
  """

  ######################
  ### default values ###
  ######################

  # volatility
  def vol(x \\ 0.3), do: x

  # time to maturity (years)
  def t(x \\ 365 / 365), do: x

  # granularity of binomial tree (levels)
  def levels(x \\ 50), do: x

  # strike price
  def k(x \\ 40.0), do: x

  # stock price present value
  def s(x \\ 45.0), do: x

  # annual risk free rate continuous compounding
  def r(x \\ 0.05), do: x

  #######################################
  ### start() used during development ###
  #######################################

  def start() do
    IO.puts("")
    IO.puts("For: s=#{s()}, k=#{k()}, vol=#{vol()}, t=#{t()}, r=#{r()}, levels=#{levels()}")
    IO.puts("Value of call option is: #{simplecall()}")
    IO.puts("")
  end

  def test_convergence() do
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
    callnode(cl, sl, gu, r, dt)
  end

  ###############
  ### library ###
  ###############

  @doc """
       simplecall/6
       stock price, strike price, annual volatility, time yrs, levels, risk-free rate
       iex> Options.European.simplecall(100.0, 125.0, 0.5, 1.0, 5, 0.06)
       12.627410465807767
  """
  def simplecall(s \\ s(), k \\ k(), v \\ vol(), t \\ t(), n \\ levels(), r \\ r()) do
    with dt = dt(t, n),
         gu = voltorate(v, dt),
         sf = leaves(s, gu, n) do
      sf
      |> cleaves(k)
      |> callnode(sf, gu, r, dt)
    end
  end

  @doc """
      leaves/3
       creates the end of the tree
       iex> Options.European.leaves(75.0, 0.8, 6)
       [286.102294921875, 183.10546875000003, 117.18750000000006, 75.00000000000004, 48.00000000000004, 30.720000000000027, 19.660800000000023]
  """
  def leaves(s \\ s(), gu \\ gu(), levels \\ levels()) do
    with bottom = s * :math.pow(gd(gu), levels) do
      0..levels
      |> Enum.map(&(bottom * :math.pow(gu * gu, &1)))
    end
  end

  @doc """
      cleaves/2
      creates the end of the tree
      iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.cleaves(65.0)
      [102.69999999999999, 63.19999999999999, 33.0, 10.0, 0.0, 0.0, 0.0]
  """
  def cleaves(sleaves, k \\ k()) do
    sleaves
    |> Enum.map(&max(&1 - k, 0.0))
  end

  @doc """
        bondsf/2
        future value of bonds for hedge
        iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.bondsf([102.7, 63.2, 33.0, 10.0, 0.0, 0.0, 0.0])
        [65.0, 65.00000000000003, 65.0, 57.3, 0.0, 0.0]
  """
  def bondsf(sfl, cfl) do
    sfl
    |> pairs()
    |> Enum.zip(pairs(cfl))
    |> Enum.map(&bfhelper(&1))
  end

  def bfhelper({[_, _], [x, x]}), do: 0.0
  def bfhelper({[sfu, sfd], [cfu, cfd]}), do: (cfu * sfd - sfu * cfd) / (cfu - cfd)

  @doc """
        bondsp/3
        discounted bonds
        iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.bondsp(0.06, 0.50)
        [162.74371597608481, 124.41111740091874, 95.10366228775379, 72.78341501613811, 55.606529072329515, 42.50551436942465, 32.50992537387502]
  """
  def bondsp(bf, r \\ r(), dt \\ dt()) do
    bf |> Enum.map(&(&1 * :math.exp(-r * dt)))
  end

  @doc """
        htops/2
        future value(s) of hedged portfolio
        iex> [167.7, 128.2, 98.0, 75.0, 57.3, 43.8, 33.5] |> Options.European.htops([102.7, 63.2, 33.0, 10.0, 0.0, 0.0, 0.0])
        [25.499999999999986, 34.8, 42.0, 47.3, 43.8, 33.5]
  """
  def htops(sfl, bfl) do
    sfl
    |> List.delete_at(0)
    |> Enum.zip(bfl)
    |> Enum.map(&htpshelper(&1))
  end

  defp htpshelper({x, y}), do: x - y

  @doc """
        sfratios/2
        ratios for adjusting hedged portfolios to call future values
        iex> [25.5, 34.8, 41.9, 47.3, 43.8, 33.5] |> Options.European.sfratios([102.7, 63.2, 33.0, 10.0, 0.0, 0.0, 0.0])
        [0.40348101265822783, 1.0545454545454545, 4.1899999999999995, 0.0, 0.0, 0.0]
  """
  def sfratios(htops, cfl) do
    cfl
    |> List.delete_at(0)
    |> Enum.zip(htops)
    |> Enum.map(&sfrhelper(&1))
  end

  defp sfrhelper({0.0, _}), do: 0.0
  defp sfrhelper({x, y}), do: y / x

  @doc """
        callp/3
        call values back one layer
        iex> [0.6, 0.55, 0.65] |> Options.European.callp([50.0, 100.0, 200.0], [50.0, 100.0, 100.0])
        [0.0, 0.0, 153.84615384615384]
  """
  def callp(hr, sp, bp) do
    Enum.zip([sp, bp, hr])
    |> Enum.map(&cphelper(&1))
  end

  defp cphelper({_sp, _bp, 0.0}), do: 0.0
  defp cphelper({sp, bp, hr}), do: (sp - bp) / hr

  @doc """
        callagain/5
        valuing call prices back one layer
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

  @doc """
        callnode/5
        present value of call option
        iex> [0.0, 0.0, 0.0, 14.3, 49.5, 95.5] |> Options.European.callnode([51.1, 66.8, 87.4, 114.3, 149.5, 195.5], 1.14, 0.07, 0.25)
        17.61075364545998
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
      |> hd()
    end
  end

  def callnode(cf, sf, gu, r, dt) do
    with sp = sreduce(sf, gd(gu)) do
      callagain(sf, cf, gu, r, dt)
      |> callnode(sp, gu, r, dt)
    end
  end

  @doc """
      dt/2
      duration of time step given number of levels and time to maturity
      iex> Options.European.dt(1.0, 5)
      0.2
  """
  def dt(t \\ t(), l \\ levels()) do
    t / l
  end

  @doc """
      gu/2
      up growth rate given volatility and duration of time step
      iex> Options.European.gu(0.3, 0.2)
      1.1435804413868396
  """
  def gu(v \\ vol(), dt \\ dt()) do
    U.voltorate(v, dt)
  end

  @doc """
      gd/1
      down growth rate given up growth rate for symetric tree
      iex> Options.European.gd(2.0)
      0.5
  """
  def gd(gu \\ gu()) do
    1.0 / gu
  end

  # annual volatility to growth rate per delta-t in years
  def voltorate(volatility, dt) do
    (volatility * :math.sqrt(dt))
    |> :math.exp()
  end

  @doc """
      iex> [1,2,3,4,5] |> Options.European.pairs()
      [[1,2], [2,3], [3,4], [4,5]]
  """
  # splits a future price distribution into ordered pairs
  def pairs([d, u]), do: [[d, u]]
  def pairs(dist), do: [[hd(dist), hd(tl(dist))] | pairs(tl(dist))]

  @doc """
      reduce/2
      steps stock price list down binomial tree by single layer
      iex> [0.25, 1.0, 4.0] |> Options.European.sreduce(0.5)
      [0.5, 2.0]
  """
  def sreduce(slist, gd \\ gd()) do
    slist
    |> List.delete_at(0)
    |> Enum.map(&(&1 * gd))
  end

  @doc """
      clist/2
      provides call option values at end of binomial tree
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
