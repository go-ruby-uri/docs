# Usage & API

The public API lives at the module root (`github.com/go-ruby-uri/uri`). It is **Ruby-shaped but Go-idiomatic**: `Parse` / `Merge` / `Normalize` mirror Ruby's `URI.parse` / `URI#merge` / `URI#normalize`, while the surface follows Go conventions — an explicit `error`, value types, no global state.

!!! success "Status: implemented"
    The library is built and importable as `github.com/go-ruby-uri/uri`, bound into
    `rbgo` as a native module; see [Roadmap](roadmap.md).

## Install

```sh
go get github.com/go-ruby-uri/uri
```

## Worked example

```go
u, _ := uri.Parse("https://x@example.com:8443/a?b=1#f")
h := u.Host                                  // "example.com"
n := u.Normalize().String()
q := uri.EncodeWWWForm(map[string]string{"q": "a b"})  // "q=a+b"
```

## Shape

```go
// Parse splits a URI string into its components (URI.parse).
func Parse(s string) (*URI, error)

// Merge resolves a relative reference against u (URI#merge / +).
func (u *URI) Merge(ref string) (*URI, error)

// Normalize lower-cases scheme and host, collapses default ports
// and dot-segments (URI#normalize).
func (u *URI) Normalize() *URI

// EncodeWWWForm form-encodes a map or pairs (URI.encode_www_form).
func EncodeWWWForm(m any) string
```

## MRI conformance

Correctness is defined by reference Ruby. A **differential oracle** runs a wide
corpus through both the system `ruby` and this library and compares the results
**byte-for-byte** — not approximated from memory. The oracle tests skip
themselves where `ruby` is not on `PATH` (e.g. the qemu arch lanes), so the
cross-arch builds still validate the library.

## Relationship to Ruby

`go-ruby-uri/uri` is **standalone and reusable**, and is the backend bound into
[go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo` as a
native module — the same way [go-ruby-regexp](https://github.com/go-ruby-regexp)
and [go-ruby-erb](https://github.com/go-ruby-erb) are bound. The dependency runs
the other way: this library has no dependency on the Ruby runtime.
