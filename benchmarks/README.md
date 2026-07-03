<!-- SPDX-License-Identifier: BSD-3-Clause -->
# `go-ruby-uri` library-level benchmark harness

Reproducible, cross-runtime benchmark of the **pure-Go `go-ruby-uri/uri`
library** against the reference Ruby runtimes (MRI, MRI + YJIT, JRuby,
TruffleRuby). It measures the **library primitive** through its Go API, isolated
from the rbgo interpreter, so the numbers answer: *is the pure-Go implementation
as fast as the reference runtime's own `uri`?*

## Layout

- `go/`          — self-contained Go driver; `go.mod` pins the **published**
  library by pseudo-version (no `replace`). The built `go/bench` binary is
  `.gitignore`d.
- `ruby/uri.rb`  — the equivalent workload; `ruby/_harness.rb` is the shared
  timer.
- `run.sh`       — verifies the Go output is byte-identical to MRI, then runs
  every available runtime and prints one Markdown table per sub-benchmark (ns/op
  + ratio vs MRI).

## Run

```sh
bash benchmarks/run.sh
```

Environment knobs: `OUTER` (timed passes, default 25), `WARM` (untimed warm-up
passes, default 3), and `RUBY`/`JRUBY`/`TRUFFLERUBY` to select runtime binaries.

## Ops measured

`URI.parse` (an http URL with userinfo + port + query + fragment), building a URI
(`URI::Generic.build`), `URI.encode_www_form` / `URI.decode_www_form`, and
`URI::DEFAULT_PARSER.escape` / `.unescape`. Ruby's `uri` is pure-Ruby stdlib, so
parity is algorithmically reachable.

## Method

Each process runs `WARM` untimed passes (to let the JVM / GraalVM JITs warm up),
then `OUTER` timed passes of a fixed inner loop, timed with a monotonic clock;
the **best** pass is reported as **ns/op**. Interpreter start-up is outside the
timed region. The Go driver and the Ruby script build **identical inputs**, and
`run.sh` checks the Go driver's `verify` output **byte-identical to MRI** (parsed
component fields + encoded/escaped strings) before any timing — a mismatch
aborts. Results are published, dated, in `../docs/performance.md`.
