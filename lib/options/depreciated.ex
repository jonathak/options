defmodule Options.Depreciated do
  @moduledoc """
  Various functions for evaluating call options using binomial method.
  """

  # annual volatility to growth rate per delta-t in years
  def voltorate(volatility, dt) do
    with exponent = volatility * :math.sqrt(dt) do
      :math.exp(exponent)
    end
  end

  @doc """
      iex> Options.Depreciated.split(100, 2.0)
      [50.0, 200.0]
  """
  # split/2
  # equity (stock) price progression, symetric
  def split(s, gu) do
    with gd = 1 / gu, do: split(s, gu, gd)
  end

  @doc """
      iex> Options.Depreciated.split(100, 2.0, 0.5)
      [50.0, 200.0]
  """
  # split/3
  # equity (stock) price progression
  def split(s, gu, gd), do: [s * gd, s * gu]

  @doc """
      iex> Options.Depreciated.revsplit([0.125, 0.5], 2.0, 0.5)
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
      iex> Options.Depreciated.revsplit([0.125, 0.5], 2.0)
      0.25
  """
  # revsplit/2
  # reverse split
  def revsplit([sfd, sfu], gu) do
    with gd = 1 / gu, do: revsplit([sfd, sfu], gu, gd)
  end

  @doc """
      iex> Options.Depreciated.bondp(100, 0.05, 1.0)
      95.1229424500714
  """
  # bondp/3
  # pres val of bf bond future
  def bondp(bf, r, dt), do: bf * :math.exp(-r * dt)

  @doc """
      iex> Options.Depreciated.callf([50, 200], 100)
      [0, 100]
  """
  # callf/2
  # call future value
  def callf([sd, su], ex), do: [max(0, sd - ex), max(0, su - ex)]

  @doc """
      iex> Options.Depreciated.bondf([50, 200], [50, 200])
      0
  """

  @doc """
      iex> [50.0, 200.0] |> Options.Depreciated.expand(2.0, 0.5)
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
      iex> Options.Depreciated.spread(100.0, 2, 2.0, 0.5)
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
      iex> Options.Depreciated.myuniq([100.0, 200.0, 200.01, 200.3, 300.0])
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
      iex> Options.Depreciated.shave(200.0, [200.0, 200.01, 200.3, 300.0])
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
      iex> [1,2,3,4,5] |> Options.Depreciated.pairs()
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
      iex> [0.125, 0.5, 0.5, 2.0, 0.5, 2.0, 2.0, 8.0] |> Options.Depreciated.calldist(1.0)
      [0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 7.0]
  """
  # calldist/2
  # forward call value distrbution
  def calldist(stockdist, ex) do
    stockdist
    |> Enum.map(&max(0.0, &1 - ex))
  end
end
