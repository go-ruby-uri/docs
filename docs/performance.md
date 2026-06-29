# Performance

`go-ruby-uri/uri` is the pure-Go library that
[`rbgo`](https://github.com/go-embedded-ruby/ruby) binds for Ruby's `uri`. This
page records a **comparative benchmark** of that module against the reference
Ruby runtimes, part of the ecosystem-wide per-module parity suite.

## What is measured

The **same** Ruby script — `URI.parse` + component access + `to_s` round-trip in a loop — is run under every runtime. `rbgo`'s
number reflects **this pure-Go library doing the work**; every other column is
that interpreter's own `uri` stdlib. So the comparison is the **Ruby-visible
operation**, apples-to-apples across interpreters. The script prints a
deterministic checksum and its output is checked **byte-identical to MRI**
before timing.

- **Host:** Apple M4 Max, macOS (darwin/arm64). **Method:** best-of-5 wall time
  (best, not mean, to suppress scheduler noise); single-shot processes, no
  warm-up beyond the script's own loop.
- **Runtimes:** `ruby 4.0.5 +PRISM` (MRI, the oracle) and `ruby --yjit`;
  `jruby 10.1.0.0` (OpenJDK 25); `truffleruby 34.0.1` (GraalVM CE Native).
- The benchmark script and harness live in rbgo's repo under
  [`bench/modules/`](https://github.com/go-embedded-ruby/ruby/tree/main/bench/modules)
  (`uri.rb` + `run.sh`). Reproduce:
  `RBGO=./rbgo TRUFFLE=truffleruby bash bench/modules/run.sh 5`.

## Result (best of 5, ms)

| Runtime | time | vs MRI |
| --- | ---: | ---: |
| **rbgo** (go-ruby-uri) | 90 | 0.24× |
| MRI (ruby 4.0.5) | 370 | 1.00× |
| MRI + YJIT | 310 | 0.84× |
| JRuby 10.1.0.0 | 1770 | 4.78× |
| TruffleRuby 34.0.1 | 2200 | 5.95× |

rbgo runs on **go-ruby-uri** and is **~4x faster than MRI** here (0.24x) — MRI's URI is Ruby-coded; the pure-Go parser+serializer round-trip wins clearly. (At ~90 ms this is a fast row; treat the ratio as order-of-magnitude.)

!!! note "Honest framing"
    JRuby and TruffleRuby are timed **cold, single-shot**, so they carry JVM /
    Graal startup on every run — read them as one-shot `ruby file.rb` costs, the
    same way `rbgo` and MRI are measured, not as steady-state JIT numbers. Rows
    that complete in well under ~200 ms carry the most relative noise; treat
    their ratios as order-of-magnitude. These are real measured numbers from the
    2026-06-29 run — nothing is cherry-picked.
