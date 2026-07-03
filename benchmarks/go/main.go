// SPDX-License-Identifier: BSD-3-Clause
//
// Library-level benchmark driver for the pure-Go go-ruby-uri/uri library.
// Mirrors ruby/uri.rb exactly: same URL, same form pairs, same escape input,
// same iteration counts. Run with the single arg "verify" to print the
// canonical outputs run.sh diffs against MRI before any timing.
package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/go-ruby-uri/uri"
)

// Inputs are byte-identical to ruby/uri.rb.
const url = "https://user:secret@www.example.com:8443/path/to/resource?q=ruby+uri&lang=en&page=2#section-3"

var form = [][2]string{{"q", "ruby uri"}, {"lang", "en & fr"}, {"page", "2"}, {"tag", "a+b/c"}}

const formEnc = "q=ruby+uri&lang=en+%26+fr&page=2&tag=a%2Bb%2Fc"
const escIn = "café/naïve path?q=a b&x=1"

var escOut = uri.EscapeDefault(escIn)

// buildURI reconstructs the parsed URL from its components (URI::Generic.build).
func buildURI() *uri.URI {
	return uri.Build("https", "user:secret", "www.example.com", 8443, true,
		"/path/to/resource", "q=ruby+uri&lang=en&page=2", true, "section-3", true)
}

// outputs renders every op's result as "op|value" lines, matching uri.rb.
func outputs() []string {
	u, _ := uri.Parse(url)
	dec, _ := uri.DecodeWWWForm(formEnc)
	dparts := make([]string, len(dec))
	for i, kv := range dec {
		dparts[i] = kv[0] + "=" + kv[1]
	}
	return []string{
		fmt.Sprintf("parse|%s|%s|%s|%d|%s|%s|%s|%s",
			u.Scheme, u.Userinfo, u.Host, u.Port, u.Path, u.Query, u.Fragment, u.String()),
		"build|" + buildURI().String(),
		"encode_www_form|" + uri.EncodeWWWForm(form),
		"decode_www_form|" + strings.Join(dparts, ","),
		"escape|" + uri.EscapeDefault(escIn),
		"unescape|" + uri.Unescape(escOut),
	}
}

func main() {
	if len(os.Args) > 1 && os.Args[1] == "verify" {
		for _, l := range outputs() {
			fmt.Println(l)
		}
		return
	}
	bench("parse", 1000, func() { u, _ := uri.Parse(url); sink = u })
	bench("build", 1000, func() { sink = buildURI().String() })
	bench("encode_www_form", 1000, func() { sink = uri.EncodeWWWForm(form) })
	bench("decode_www_form", 1000, func() { d, _ := uri.DecodeWWWForm(formEnc); sink = d })
	bench("escape", 1000, func() { sink = uri.EscapeDefault(escIn) })
	bench("unescape", 1000, func() { sink = uri.Unescape(escOut) })
}
