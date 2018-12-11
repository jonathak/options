# Options

This library contains functions useful for pricing derivative securities using the binomial arbitrage pricing method. Functional programming style with immutable state is applicable to critical systems such as automated trading and arbitrage pricing. Additionally there is potential for fault tolerant distributed calculation for large trees and/or massive number of calculations. So far the Eurpoean-style call options is implemented. 

Examples and descriptions of all functions are provided in the doctests.

Simple usage for European call option is: 

installation
$ cd options
$ mix test
$ mix european s k v t r n

Where s is stock price, k is strike price, v is annual volatility, t is time to maturity in years, r is risk free rate with continuous compounding, and n is the number of levels in the binomial tree.

Welcomed pull requests include:
. Refactoring suggestions
. Incorporation of dividends
. Expansion to American, Asian, and other option styles
. Incorporation into a supervised Genserver
. Additional error handling
. Additional documentation
. Additional testing

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

