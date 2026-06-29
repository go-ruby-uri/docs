# Roadmap

`go-ruby-uri/uri` is grown **test-first**, each capability differential-tested against MRI
rather than built in isolation. Ruby's URI library — the
deterministic, interpreter-independent slice extracted from rbgo's internals — is
**complete**.

| Stage | What | Status |
| --- | --- | --- |
| Parse & components | `URI.parse(s)` splitting scheme / userinfo / host / port / path / query / fragment, with the per-scheme generic/HTTP/HTTPS/FTP/LDAP shapes Ruby's URI uses. | **Done** |
| Build & merge | Constructing a URI from components and `merge` / `+` for relative-reference resolution, following RFC 3986 the way reference Ruby does. | **Done** |
| Normalize | `normalize` lower-casing the scheme and host, collapsing default ports and dot-segments, matching MRI byte-for-byte. | **Done** |
| `encode_www_form` & escaping | Form encoding/decoding and `escape`/`unescape` with Ruby's reserved-character tables. | **Done** |
| Error taxonomy | The `URI::InvalidURIError` / `URI::InvalidComponentError` / `URI::BadURIError` hierarchy, raised on the same inputs as reference Ruby. | **Done** |
| Differential oracle & coverage | A wide URI corpus parsed, built and normalized both here and by the system `ruby`/`uri`, compared byte-for-byte; 100% coverage, gofmt + go vet clean, green across all six 64-bit Go arches and three OSes. | **Done** |

## Documented out-of-scope boundaries

These are **deliberate**, recorded so the module's surface is unambiguous:

- **No interpreter.** The library implements the deterministic algorithm; it
  never runs arbitrary Ruby. Anything that needs a live binding or evaluation is
  the consumer's job — that is why `rbgo` binds this module rather than the
  reverse.
- **Reference is reference Ruby (MRI).** Byte-for-byte conformance targets MRI's
  behaviour; differences across MRI releases are matched to the reference used by
  the differential oracle.
- **Standalone & reusable.** The module has no dependency on the Ruby runtime;
  the dependency runs the other way.

See [Usage & API](api.md) for the surface and [Why pure Go](why.md) for the
deterministic/interpreter split.
