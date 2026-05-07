#!/usr/bin/env bash
# usage: color <value>
#
# Convert between hex, rgb, and hsl color formats. Accepts:
#   color "#ff8800"
#   color "ff8800"
#   color "rgb(255,136,0)"
#   color "hsl(32, 100%, 50%)"
#
# Outputs all three representations plus a small ANSI swatch (in 24-bit
# terminals).

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

case "${1:-}" in
  -h|--help|"") show_help_and_exit ;;
esac

input="$*"

python3 - "$input" <<'PY'
import sys, re

raw = sys.argv[1].strip().lower()

def clamp(v, lo, hi): return max(lo, min(hi, v))

def rgb_to_hex(r,g,b): return "#{:02x}{:02x}{:02x}".format(int(r), int(g), int(b))

def rgb_to_hsl(r,g,b):
    r,g,b = r/255.0, g/255.0, b/255.0
    mx, mn = max(r,g,b), min(r,g,b)
    l = (mx+mn)/2
    if mx == mn:
        h = s = 0
    else:
        d = mx - mn
        s = d/(2-mx-mn) if l > 0.5 else d/(mx+mn)
        if   mx == r: h = ((g-b)/d + (6 if g < b else 0))
        elif mx == g: h = (b-r)/d + 2
        else:         h = (r-g)/d + 4
        h *= 60
    return round(h), round(s*100), round(l*100)

def hsl_to_rgb(h, s, l):
    h = (h % 360) / 360.0
    s, l = s/100.0, l/100.0
    if s == 0:
        v = round(l*255)
        return v, v, v
    def hue(p, q, t):
        if t < 0: t += 1
        if t > 1: t -= 1
        if t < 1/6: return p + (q-p)*6*t
        if t < 1/2: return q
        if t < 2/3: return p + (q-p)*(2/3 - t)*6
        return p
    q = l*(1+s) if l < 0.5 else l + s - l*s
    p = 2*l - q
    return (round(hue(p,q,h+1/3)*255), round(hue(p,q,h)*255), round(hue(p,q,h-1/3)*255))

# Parse input
m = re.fullmatch(r"#?([0-9a-f]{3}|[0-9a-f]{6})", raw)
rgb = None
if m:
    h = m.group(1)
    if len(h) == 3:
        h = ''.join(c*2 for c in h)
    rgb = (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16))

m = re.fullmatch(r"rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+).*\)", raw)
if m:
    rgb = tuple(clamp(int(x),0,255) for x in m.groups())

m = re.fullmatch(r"hsla?\(\s*(-?\d+)\s*,\s*(\d+)%?\s*,\s*(\d+)%?.*\)", raw)
if m:
    rgb = hsl_to_rgb(int(m.group(1)), clamp(int(m.group(2)),0,100), clamp(int(m.group(3)),0,100))

if rgb is None:
    print(f"Could not parse color: {raw!r}", file=sys.stderr)
    sys.exit(1)

r,g,b = rgb
hex_ = rgb_to_hex(r,g,b)
h,s,l = rgb_to_hsl(r,g,b)

print(f"HEX:  {hex_}")
print(f"RGB:  rgb({r}, {g}, {b})")
print(f"HSL:  hsl({h}, {s}%, {l}%)")
print(f"\033[48;2;{r};{g};{b}m            \033[0m  swatch")
PY
