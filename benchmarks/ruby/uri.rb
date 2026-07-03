# frozen_string_literal: true
# SPDX-License-Identifier: BSD-3-Clause
#
# Reference Ruby workload mirroring go/main.go for the go-ruby-uri parity
# benchmark. Same URL, same form pairs, same escape input, same iteration
# counts. `ruby uri.rb verify` prints the canonical outputs run.sh diffs against
# the Go driver before any timing.
require "uri"
require_relative "_harness"

URL = "https://user:secret@www.example.com:8443/path/to/resource?q=ruby+uri&lang=en&page=2#section-3"
FORM = [["q", "ruby uri"], ["lang", "en & fr"], ["page", "2"], ["tag", "a+b/c"]]
FORM_ENC = "q=ruby+uri&lang=en+%26+fr&page=2&tag=a%2Bb%2Fc"
ESC_IN = "café/naïve path?q=a b&x=1"
ESC_OUT = URI::DEFAULT_PARSER.escape(ESC_IN)

# build_uri reconstructs URL from its components (URI::Generic.build).
def build_uri
  URI::Generic.build(["https", "user:secret", "www.example.com", 8443, nil,
                      "/path/to/resource", nil, "q=ruby+uri&lang=en&page=2", "section-3"])
end

def outputs
  u = URI.parse(URL)
  dec = URI.decode_www_form(FORM_ENC).map { |k, v| "#{k}=#{v}" }.join(",")
  [
    "parse|#{u.scheme}|#{u.userinfo}|#{u.host}|#{u.port}|#{u.path}|#{u.query}|#{u.fragment}|#{u}",
    "build|#{build_uri}",
    "encode_www_form|#{URI.encode_www_form(FORM)}",
    "decode_www_form|#{dec}",
    "escape|#{URI::DEFAULT_PARSER.escape(ESC_IN)}",
    "unescape|#{URI::DEFAULT_PARSER.unescape(ESC_OUT)}",
  ]
end

if ARGV[0] == "verify"
  puts outputs
  exit
end

bench("parse",           1000) { URI.parse(URL) }
bench("build",           1000) { build_uri.to_s }
bench("encode_www_form", 1000) { URI.encode_www_form(FORM) }
bench("decode_www_form", 1000) { URI.decode_www_form(FORM_ENC) }
bench("escape",          1000) { URI::DEFAULT_PARSER.escape(ESC_IN) }
bench("unescape",        1000) { URI::DEFAULT_PARSER.unescape(ESC_OUT) }
