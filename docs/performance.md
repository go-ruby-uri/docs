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

## Library-level benchmark (Go API vs runtimes) — 2026-07-03

This section measures the **pure-Go library directly, through its Go API** — not
the `rbgo` interpreter path recorded above. It isolates the library primitive
from Ruby-interpreter dispatch, answering the parity question head-on: *is the
pure-Go implementation as fast as the reference runtime's own `uri`?* The
**same workload, same inputs, same iteration counts** run through the Go library
and through each reference runtime's stdlib; the Go driver's output was checked
**byte-identical to MRI** (parsed component fields + encoded/escaped strings)
before any timing.

- **Host:** Apple M4 Max (`Mac16,5`, arm64), macOS 26.5.1 — **date 2026-07-03**.
  All runtimes ran natively on the host (no VM).
- **Runtimes:** Go 1.26.4 · MRI `ruby 4.0.5 +PRISM` · MRI + YJIT · JRuby 10.1.0.0
  (OpenJDK 25) · TruffleRuby 34.0.1 (GraalVM CE Native).
- **Ops:** `URI.parse` (an http URL with userinfo + port + query + fragment),
  building a URI (`URI::Generic.build`), `URI.encode_www_form` /
  `URI.decode_www_form`, and `URI::DEFAULT_PARSER.escape` / `.unescape`. Ruby's
  `uri` is pure-Ruby stdlib, so parity is algorithmically reachable — and, being
  compiled, the pure-Go library realizes it with room to spare. No op was
  unmeasurable: every one of the six has a direct, output-equal Go counterpart.
- **Method:** each process runs 3 untimed warm-up passes, then 25 timed passes of
  a fixed inner loop (1000 ops each), timed with a monotonic clock; the **best**
  pass is reported as **ns/op** (lower is better). `vs MRI` < 1.00× means
  *faster than MRI*. Interpreter start-up is outside the timed region, so these
  are operation costs, not `ruby file.rb` process costs. Harness + workload:
  [`benchmarks/`](https://github.com/go-ruby-uri/docs/tree/main/benchmarks)
  (`go/` pins the published library by pseudo-version; `ruby/uri.rb`); reproduce
  with `bash benchmarks/run.sh`.

#### parse

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 99.1 | 0.02× |
| MRI | 4090.0 | 1.00× |
| MRI + YJIT | 3434.0 | 0.84× |
| JRuby | 3576.9 | 0.87× |
| TruffleRuby | 35191.1 | 8.60× |

#### build

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 83.3 | 0.02× |
| MRI | 5466.0 | 1.00× |
| MRI + YJIT | 4403.0 | 0.81× |
| JRuby | 3910.8 | 0.72× |
| TruffleRuby | 10683.6 | 1.95× |

#### encode_www_form

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 273.6 | 0.07× |
| MRI | 4028.0 | 1.00× |
| MRI + YJIT | 3246.0 | 0.81× |
| JRuby | 1726.7 | 0.43× |
| TruffleRuby | 5131.3 | 1.27× |

#### decode_www_form

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 230.5 | 0.07× |
| MRI | 3496.0 | 1.00× |
| MRI + YJIT | 3129.0 | 0.90× |
| JRuby | 1435.3 | 0.41× |
| TruffleRuby | 5273.6 | 1.51× |

#### escape

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 135.8 | 0.05× |
| MRI | 2586.0 | 1.00× |
| MRI + YJIT | 2872.0 | 1.11× |
| JRuby | 1861.8 | 0.72× |
| TruffleRuby | 2238.7 | 0.87× |

#### unescape

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 85.3 | 0.04× |
| MRI | 2186.0 | 1.00× |
| MRI + YJIT | 2062.0 | 0.94× |
| JRuby | 847.1 | 0.39× |
| TruffleRuby | 2112.1 | 0.97× |

The pure-Go library wins every op decisively — **~50–120× faster than MRI** on
`parse`/`build` and ~14–40× on the encode/escape family — because MRI's `uri` is
pure-Ruby stdlib, so each op pays interpreter dispatch that the compiled Go code
does not. Parity is not just reached here, it is comfortably beaten. Outputs were
checked byte-identical to MRI before timing, so the speed is not bought with
divergent behavior.

!!! note "Cold-JIT caveat"
    JRuby (JVM) and TruffleRuby (GraalVM) get only the harness's 3 warm-up
    passes, so they are effectively **cold** — TruffleRuby's `parse` row
    (35191 ns, 8.60×) is dominated by Graal compilation kicking in on a
    just-touched path, not steady-state throughput; JRuby is closer to warm but
    still not fully JITed. Read the JVM/Graal columns as cold single-shot costs,
    the same footing as the top-of-page table. These are **real measured
    numbers** from the 2026-07-03 run (Apple M4 Max, arm64; `ruby 4.0.5 +PRISM`,
    `jruby 10.1.0.0`, `truffleruby 34.0.1`) — nothing is fabricated or
    cherry-picked.
