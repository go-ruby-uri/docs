# go-ruby-uri documentation

**Ruby's URI parse, build & normalize in pure Go — MRI-compatible, no cgo.**

`go-ruby-uri/uri` is a faithful, pure-Go (zero cgo) reimplementation of Ruby's URI library,
matching reference Ruby (MRI) byte-for-byte. The module path is
`github.com/go-ruby-uri/uri`.

It was **extracted from rbgo's prelude/internals into a reusable standalone
library**: the module is standalone and importable by any Go program, and it is
the backend bound into [go-embedded-ruby](https://github.com/go-embedded-ruby/ruby)
by `rbgo` as a native module — just like
[go-ruby-regexp](https://github.com/go-ruby-regexp) and
[go-ruby-erb](https://github.com/go-ruby-erb). The dependency runs the other
way: this library has **no dependency on the Ruby runtime**.

!!! success "Status: parse + build + normalize complete — MRI byte-exact"
    Faithful port of Ruby's URI: **`parse`** into scheme / userinfo / host / port / path / query / fragment, **`build`** and **`merge`** / **`+`** for relative-reference resolution per RFC 3986, **`normalize`** of scheme and host, **`encode_www_form`** and **`escape`** / **`unescape`** with Ruby's reserved-character tables, and the **`URI::InvalidURIError` / `URI::InvalidComponentError` / `URI::BadURIError`** taxonomy. Validated by a **differential oracle** against the system `ruby` / `uri` — parsed, built and normalized URIs compared byte-for-byte — at 100% coverage, `gofmt` + `go vet` clean, CI green across the six 64-bit Go targets and three OSes.

## Quick taste

```go
u, _ := uri.Parse("https://x@example.com:8443/a?b=1#f")
h := u.Host                                  // "example.com"
n := u.Normalize().String()
q := uri.EncodeWWWForm(map[string]string{"q": "a b"})  // "q=a+b"
```

## Repositories

| Repo | What it is |
| --- | --- |
| [`uri`](https://github.com/go-ruby-uri/uri) | the library — Ruby's URI in pure Go |
| [`docs`](https://github.com/go-ruby-uri/docs) | this documentation site (MkDocs Material, versioned with mike) |
| [`go-ruby-uri.github.io`](https://github.com/go-ruby-uri/go-ruby-uri.github.io) | the organization landing page (Hugo) |
| [`brand`](https://github.com/go-ruby-uri/brand) | logo and brand assets |

## Principles

- **Pure Go, `CGO_ENABLED=0`** — trivial cross-compilation, a single static
  binary, no C toolchain.
- **MRI byte-exact.** Output matches reference Ruby exactly, not approximately,
  validated by a differential oracle against the `ruby` binary.
- **Standalone & reusable.** Extracted from rbgo's internals; no dependency on
  the Ruby runtime — the dependency runs the other way.
- **100% test coverage** is the target, enforced as a CI gate, across 6 arches
  and 3 OSes.

## Where to go next

- [Why pure Go](why.md) — why this slice of Ruby is deterministic enough to live
  as a standalone, interpreter-independent Go library.
- [Usage & API](api.md) — the public surface and worked examples.
- [Roadmap](roadmap.md) — what is done and what is downstream by design.

Source lives at [github.com/go-ruby-uri/uri](https://github.com/go-ruby-uri/uri).
