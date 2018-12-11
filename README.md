# Options

This library contains functions useful for pricing derivative securities using the binomial arbitrage pricing method. Functional programming style with immutable state is applicable to critical systems such as automated trading and arbitrage pricing. Additionally there is potential for fault tolerant distributed calculation for large trees and/or massive number of calculations. So far the pricing of Eurpoean-style call option is implemented. 

Examples and descriptions of all functions are provided in the doctests.

Simple usage for a European call option is: 

<ul>
<li>installation</li>
<li>$ cd options</li>
<li>$ mix test</li>
<li>$ mix european s k v t r n</li>
</ul>

Where s is stock price, k is strike price, v is annual volatility, t is time to maturity in years, r is risk free rate with continuous compounding, and n is the number of levels in the binomial tree.

Welcomed pull requests include:
<ul>
<li>Refactoring suggestions</li>
<li>Incorporation of dividends</li>
<li>Expansion to American, Asian, and other option styles</li>
<li>Incorporation into a supervised Genserver</li>
<li>Additional error handling</li>
<li>Additional documentation</li>
<li>Additional testing</li>
</ul>

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

