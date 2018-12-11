# Options

This library contains functions useful for pricing derivative securities using the binomial arbitrage pricing method. Examples and descriptions of functions are provided in the doctests.

Simple usage for European call option is: 

mix european s k v t r n

where s is stock price, k is strike price, v is annual volatility, t is time to maturity in years, r is risk free rate with continuous compounding, and n is the number of levels in the binomial tree.

## Installation

When [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `options` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:options, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/options](https://hexdocs.pm/options).

