#!/usr/bin/env bash
#
# Copyright (c) the go-ruby-uri authors
# SPDX-License-Identifier: BSD-3-Clause
#
# Library-level cross-runtime benchmark runner for go-ruby-uri.
#
# Runs the SAME workload through (a) the pure-Go go-ruby-uri/uri library
# (benchmarks/go) and (b) each available reference Ruby runtime
# (benchmarks/ruby/uri.rb), then prints one Markdown table per sub-benchmark:
# ns/op and the ratio vs MRI.
#
# Before timing, the Go driver's output is checked BYTE-IDENTICAL to MRI's
# (parsed component fields + escaped/encoded strings); a mismatch aborts.
#
# Usage:  bash benchmarks/run.sh
# Env:    OUTER (timed passes, default 25), WARM (untimed passes, default 3),
#         RUBY / JRUBY / TRUFFLERUBY (override runtime binaries).
set -u
cd "$(dirname "$0")"

RUBY=${RUBY:-ruby}
JRUBY=${JRUBY:-jruby}
TRUFFLERUBY=${TRUFFLERUBY:-truffleruby}

RB=ruby/uri.rb
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# Build the Go driver once (binary is .gitignored).
echo "== go-ruby-uri library-level benchmark ==" >&2
echo "  building go driver ..." >&2
( cd go && go build -o bench . ) || { echo "go build failed" >&2; exit 1; }

# --- Correctness gate: Go output must equal MRI output, byte for byte. -------
echo "  verifying go output == MRI ..." >&2
GO_OUT=$(cd go && ./bench verify)
MRI_OUT=$("$RUBY" "$RB" verify)
if [ "$GO_OUT" != "$MRI_OUT" ]; then
  echo "PARITY MISMATCH — refusing to time:" >&2
  diff <(printf '%s\n' "$MRI_OUT") <(printf '%s\n' "$GO_OUT") >&2
  exit 1
fi
echo "  parity OK (${RB} outputs match MRI)" >&2

run() { # <runtime-label> <cmd...>
  local label=$1; shift
  command -v "$1" >/dev/null 2>&1 || { echo "  ($label: $1 not found — skipped)" >&2; return; }
  echo "  $label ..." >&2
  "$@" 2>/dev/null | awk -v r="$label" '$1=="RESULT"{printf "%s\t%s\t%s\n", r, $2, $3}' >> "$TMP"
}

echo "  go ..." >&2
( cd go && ./bench ) | awk '$1=="RESULT"{printf "go\t%s\t%s\n", $2, $3}' >> "$TMP"
run "mri"         "$RUBY"                "$RB"
run "mri-yjit"    "$RUBY" --yjit        "$RB"
run "jruby"       "$JRUBY"              "$RB"
run "truffleruby" "$TRUFFLERUBY"        "$RB"

echo >&2
# Emit one Markdown table per sub-benchmark (label), runtimes as rows.
awk -F'\t' '
  { key=$2; rt=$1; ns=$3; labels[key]=1; val[rt SUBSEP key]=ns; rts[rt]=1 }
  END {
    order="go mri mri-yjit jruby truffleruby"
    n=split(order, ord, " ")
    ln=0; for (k in labels) lab[++ln]=k
    for (i=1;i<=ln;i++) for (j=i+1;j<=ln;j++) if (lab[j]<lab[i]){t=lab[i];lab[i]=lab[j];lab[j]=t}
    for (i=1;i<=ln;i++){
      k=lab[i]
      printf "\n#### %s\n\n", k
      print  "| Runtime | ns/op | vs MRI |"
      print  "| --- | ---: | ---: |"
      base=val["mri" SUBSEP k]
      for (o=1;o<=n;o++){
        rt=ord[o]; v=val[rt SUBSEP k]
        if (v=="") continue
        ratio=(base!=""&&base+0>0)? sprintf("%.2f×", v/base) : "—"
        name=rt
        if (rt=="go") name="**go-ruby (pure Go)**"
        else if (rt=="mri") name="MRI"
        else if (rt=="mri-yjit") name="MRI + YJIT"
        else if (rt=="jruby") name="JRuby"
        else if (rt=="truffleruby") name="TruffleRuby"
        printf "| %s | %s | %s |\n", name, v, ratio
      }
    }
  }
' "$TMP"
