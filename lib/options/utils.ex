defmodule Options.Utils do
  @moduledoc """
  Various functions for evaluating call options using binomial method.
  """

  @doc """
      iex> Options.Utils.simplecall(100.0, 5, 1.0, 0.1, 100.0, 0.05)
      6.257116861602118
  """
  # simplecall/7
  # valuation of call option given simple parameters
  # stock price, time granularity, volatility, exercize price, risk free rate
  def simplecall(sp, levels, t, vol, ex, r) do
    with dt = t / levels,
         gu = voltorate(vol, dt),
         gd = 1 / gu,
         fut_stk_prc_dist = spread(sp, levels, gu, gd),
         fut_cal_prc_dist = Enum.map(fut_stk_prc_dist, &max(0.0, &1 - ex)),
         combined = Enum.zip(pairs(fut_stk_prc_dist), pairs(fut_cal_prc_dist)) do
      callnode(combined, gu, gd, r, dt)
    end
  end

  # simplecall/8
  # valuation of call option given simple parameters
  # stock price, time granularity, gains up and down, exercize price, risk free rate
  def simplecall(sp, levels, t, gu, gd, ex, r) do
    with dt = t / levels,
         fut_stk_prc_dist = spread(sp, levels, gu, gd),
         fut_cal_prc_dist = Enum.map(fut_stk_prc_dist, &max(0.0, &1 - ex)),
         combined = Enum.zip(pairs(fut_stk_prc_dist), pairs(fut_cal_prc_dist)) do
      callnode(combined, gu, gd, r, dt)
    end
  end

  # annual volatility to growth rate per delta-t in years
  def voltorate(volatility, dt) do
    with exponent = volatility * :math.sqrt(dt) do
      :math.exp(exponent)
    end
  end

  @doc """
      iex> Options.Utils.split(100, 2.0)
      [50.0, 200.0]
  """
  # split/2
  # equity (stock) price progression, symetric
  def split(s, gu) do
    with gd = 1 / gu, do: split(s, gu, gd)
  end

  @doc """
      iex> Options.Utils.split(100, 2.0, 0.5)
      [50.0, 200.0]
  """
  # split/3
  # equity (stock) price progression
  def split(s, gu, gd), do: [s * gd, s * gu]

  @doc """
      iex> Options.Utils.revsplit([0.125, 0.5], 2.0, 0.5)
      0.25
  """
  # revsplit/3
  # reverse split
  def revsplit([sfd, sfu], gu, gd) do
    with s1 = sfu / gu,
         s2 = sfd / gd do
      if abs(s1 - s2) / s1 < 0.0001 do
        s1
      else
        :error
      end
    end
  end

  @doc """
      iex> Options.Utils.revsplit([0.125, 0.5], 2.0)
      0.25
  """
  # revsplit/2
  # reverse split
  def revsplit([sfd, sfu], gu) do
    with gd = 1 / gu, do: revsplit([sfd, sfu], gu, gd)
  end

  @doc """
      iex> Options.Utils.bondp(100, 0.05, 1.0)
      95.1229424500714
  """
  # bondp/3
  # pres val of bf bond future
  def bondp(bf, r, dt), do: bf * :math.exp(-r * dt)

  @doc """
      iex> Options.Utils.callf([50, 200], 100)
      [0, 100]
  """
  # callf/2
  # call future value
  def callf([sd, su], ex), do: [max(0, sd - ex), max(0, su - ex)]

  @doc """
      iex> Options.Utils.bondf([50, 200], [50, 200])
      0
  """
  # bondf/2
  # bond future value that satisfies hedge position w/o ratio
  def bondf([sfd, _sfu], [cfd, _cfu]), do: sfd - cfd

  @doc """
      iex> Options.Utils.hedgef([50, 200], [0, 100])
      [0, 150]
  """
  # hedgef/2
  # future hedge portfolio, bf bond future
  def hedgef([sfd, sfu], [cfd, cfu]) do
    with bf = bondf([sfd, sfu], [cfd, cfu]) do
      [sfd - bf, sfu - bf]
    end
  end

  @doc """
      iex> Options.Utils.hedgep(3.0, 2.0)
      1.0
  """
  # hedgep/2
  # pres val hedge portfolio, stock present bond present
  def hedgep(sp, bp) do
    sp - bp
  end

  @doc """
      iex> Options.Utils.ratio([1.0, 2.0], [0.0, 1.0])
      2.0
  """
  # ratio/2
  # hedge future down, up, call etc.
  def ratio([_hfd, hfu], [_cfd, cfu]) do
    hfu / cfu
  end

  @doc """
      iex> Options.Utils.callp(100, [50, 200], [0, 100], 0.05, 5.0)
      40.7066405642865
  """
  # callp/5
  # present value of call using forward call prices from tree
  # sf stock present future down up, exercise price, hcr hedge call ratio
  def callp(sp, [sfd, sfu], [cfd, cfu], r, dt) do
    if cfu > 0.0 do
      with sf = [sfd, sfu],
           cf = [cfd, cfu],
           hcr = ratio(hedgef(sf, cf), cf),
           bf = bondf(sf, cf),
           bp = bondp(bf, r, dt) do
        hedgep(sp, bp) / hcr
      end
    else
      0.0
    end
  end

  @doc """
      iex> Options.Utils.callpp(100, [50, 200], 100, 0.05, 1.0)
      34.95901918330953
  """
  # callpp/5
  # present value call, future call prices inferred
  def callpp(sp, [sd, su], ex, r, dt) do
    if ex >= sd and ex < su do
      (sp - bondp(sd, r, dt)) * (su - ex) / (su - sd)
    else
      if ex < sd do
        sp - bondp(ex, r, dt)
      else
        0.0
      end
    end
  end

  @doc """
      iex> [50.0, 200.0] |> Options.Utils.expand(2.0, 0.5)
      [[25.0, 100.0], [100.0, 400.0]]
  """
  # expand/1
  # add layer to stock price progression
  def expand([d, u], gu, gd) do
    if is_float(d) or is_integer(d) do
      [split(d, gu, gd), split(u, gu, gd)]
    else
      [expand(d, gu, gd), expand(u, gu, gd)]
    end
  end

  @doc """
      iex> Options.Utils.spread(100.0, 2, 2.0, 0.5)
      [25.0, 100.0, 400.0]
  """
  # spread/2
  # stock price progression to n levels
  def spread(s, n, gu, gd) do
    if n > 1 do
      1..(n - 1)
      |> Enum.reduce(split(s * 1.0, gu * 1.0, gd * 1.0), fn _x, acc -> expand(acc, gu, gd) end)
      |> List.flatten()
      |> Enum.sort()
      |> myuniq()
    else
      split(s, gu, gd)
    end
  end

  @doc """
      iex> Options.Utils.myuniq([100.0, 200.0, 200.01, 200.3, 300.0])
      [100.0, 200.0, 300.0]
  """
  # myuniq/1
  # eliminates close values that were retained due to rounding errors
  def myuniq(nums) do
    [x | y] = nums

    if y == [] do
      [x]
    else
      if abs(x - hd(y)) / x < 0.01 do
        [x | myuniq(shave(x, y))]
      else
        [x | myuniq(y)]
      end
    end
  end

  @doc """
      iex> Options.Utils.shave(200.0, [200.0, 200.01, 200.3, 300.0])
      [300.0]
  """
  # shave/2
  # helper for myuniq
  def shave(x, y) do
    if abs(x - hd(y)) / x < 0.01 do
      shave(x, tl(y))
    else
      y
    end
  end

  @doc """
      iex> [1,2,3,4,5] |> Options.Utils.pairs()
      [[1,2], [2,3], [3,4], [4,5]]
  """
  # splits a future price distribution into ordered pairs
  def pairs(dist) do
    if length(dist) == 2 do
      [dist]
    else
      [[hd(dist), hd(tl(dist))] | pairs(tl(dist))]
    end
  end

  @doc """
      iex> [0.125, 0.5, 0.5, 2.0, 0.5, 2.0, 2.0, 8.0] |> Options.Utils.calldist(1.0)
      [0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 7.0]
  """
  # calldist/2
  # forward call value distrbution
  def calldist(stockdist, ex) do
    stockdist
    |> Enum.map(&max(0.0, &1 - ex))
  end

  @doc """
      iex> [1, 2, 3] |> 
      ...> Options.Utils.bothsandc([4, 5, 6])
      [{[1,2],[4,5]}, {[2,3], [5,6]}]
  """
  # bothsandc/2
  # combining future stock and future call distributions 
  def bothsandc(stockdist, calldist), do: Enum.zip(pairs(stockdist), pairs(calldist))

  @doc """
      iex> combined = [{[12.5, 50.0], [0.0,0.0]}, {[50.0, 200.0], [0.0,100.0]}, {[200.0,800.0],[100.0, 700.0]}]
      iex> Options.Utils.callcalc(combined, 2.0, 0.5, 0.05, 0.33)
      [[0.0, 33.87882068697758], [33.87882068697758, 301.6364620609328]]
  """
  # callcalc/5
  # calculates call price one layer toward node of binomial tree
  def callcalc(combined, gu, gd, r, dt) do
    combined
    |> Enum.map(&cchelper(&1, gu, gd, r, dt))
    |> pairs()
  end

  # cchelper/5
  # helper function for callcalc (above)
  defp cchelper(pair, gu, gd, r, dt) do
    with sf = elem(pair, 0),
         cf = elem(pair, 1),
         sp = revsplit(sf, gu, gd) do
      callp(sp, sf, cf, r, dt)
    end
  end

  @doc """
      iex> combined = [{[12.5, 50.0], [0.0,0.0]}, {[50.0, 200.0], [0.0,100.0]}, {[200.0,800.0],[100.0, 700.0]}]
      iex> Options.Utils.callnode(combined, 2.0, 0.5, 0.05, 0.33)
      46.89631615583375
  """
  # callnode/5
  # calculates call value at node of binomial tree
  def callnode(combined, gu, gd, r, dt) do
    if length(combined) == 1 do
      cchelper(hd(combined), gu, gd, r, dt)
    else
      with sreduced =
             Enum.map(combined, &elem(&1, 0))
             |> Enum.map(&revsplit(&1, gu, gd))
             |> pairs(),
           creduced = callcalc(combined, gu, gd, r, dt),
           rdist = Enum.zip(sreduced, creduced) do
        callnode(rdist, gu, gd, r, dt)
      end
    end
  end

  #######################################
  ### below are depreciated functions ###
  #######################################

  @doc """
      iex> [[[1.0, 1.0], [1.0, 1.0]], [[1.0, 1.0], [1.0, 1.0]]] |> Options.Utils.depth()
      3
  """
  # depth of stock price progression tree (depreciated)
  def depth([x, _y]) do
    if is_float(x) or is_integer(x) do
      1
    else
      1 + depth(x)
    end
  end

  # (depreciated)
  def scoop(tree) do
    if not is_list(hd(tree)) do
      tree
    else
      scoop(hd(tree))
    end
  end
end