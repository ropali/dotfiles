#!/usr/bin/env python3
"""Generate an OpenCode V2 (base/hue) theme from a Noctalia palette JSON.

Usage: gen-opencode-theme.py <palette.json> <out-theme.json>

The palette JSON is produced by Noctalia from
`~/.config/opencode/noctalia-palette.template.json`.
"""
import json
import sys


def h2r(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def r2h(rgb):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(x))) for x in rgb)


def mix(c1, c2, t):
    a, b = h2r(c1), h2r(c2)
    return r2h(tuple(a[i] * (1 - t) + b[i] * t for i in range(3)))


def lighten(c, t):
    return mix(c, "#ffffff", t)


def darken(c, t):
    return mix(c, "#000000", t)


def scale(base):
    """Dark-theme 9-step scale: 100 = lightest, 900 = darkest."""
    return {
        "100": lighten(base, 0.72),
        "200": lighten(base, 0.52),
        "300": lighten(base, 0.32),
        "400": lighten(base, 0.14),
        "500": base,
        "600": darken(base, 0.16),
        "700": darken(base, 0.32),
        "800": darken(base, 0.50),
        "900": darken(base, 0.66),
    }


def build(palette):
    # Neutral/gray scale: smooth gradient from light foreground to dark surface.
    gray = {}
    light = palette["on_surface_variant"]
    dark = palette["surface"]
    steps = [100, 200, 300, 400, 500, 600, 700, 800]
    for i, step in enumerate(steps):
        gray[str(step)] = mix(light, dark, i / (len(steps) - 1))
    gray["900"] = palette.get("shadow", darken(dark, 0.3))

    hue = {
        "gray": gray,
        "red": scale(palette["error"]),
        "orange": scale(palette["tn_yellow"]),
        "yellow": scale(palette["tn_yellow"]),
        "green": scale(palette["tn_green"]),
        "cyan": scale(palette["tn_cyan"]),
        "blue": scale(palette["primary"]),
        "purple": scale(palette["tn_magenta"]),
        "accent": "$hue.blue",
        "interactive": "$hue.blue",
        "neutral": "$hue.gray",
    }

    base = {
        "categorical": ["accent", "purple", "green", "blue"],
        "text": {
            "base": "$hue.neutral.200",
            "muted": "$hue.neutral.400",
            "faint": "$hue.neutral.500",
            "action": {
                "primary": {
                    "base": "$hue.interactive.300",
                    "$hovered": "$hue.interactive.200",
                    "$pressed": "$hue.interactive.400",
                },
                "secondary": {
                    "base": "$hue.neutral.300",
                    "$hovered": "$hue.neutral.200",
                },
                "destructive": {
                    "base": "$hue.red.300",
                    "$hovered": "$hue.red.200",
                },
            },
            "formfield": {
                "base": "$hue.neutral.200",
                "$hovered": "$hue.neutral.100",
            },
            "feedback": {
                "error": {"base": "$hue.red.300", "muted": "$hue.red.500"},
                "warning": {"base": "$hue.orange.300", "muted": "$hue.orange.500"},
                "success": {"base": "$hue.green.300", "muted": "$hue.green.500"},
                "info": {"base": "$hue.blue.300", "muted": "$hue.blue.500"},
            },
        },
        "background": {
            "base": "$hue.neutral.800",
            "raised": {
                "base": "$hue.neutral.700",
                "high": "$hue.neutral.600",
                "max": "$hue.neutral.500",
            },
            "action": {
                "primary": {
                    "base": "$hue.interactive.500",
                    "$hovered": "$hue.interactive.400",
                    "$pressed": "$hue.interactive.600",
                },
                "secondary": {
                    "base": "$hue.neutral.600",
                    "$hovered": "$hue.neutral.500",
                },
                "destructive": {
                    "base": "$hue.red.500",
                    "$hovered": "$hue.red.400",
                },
            },
            "formfield": {
                "base": "$hue.neutral.700",
                "$hovered": "$hue.neutral.600",
            },
            "feedback": {
                "error": {"base": "$hue.red.800"},
                "warning": {"base": "$hue.orange.800"},
                "success": {"base": "$hue.green.800"},
                "info": {"base": "$hue.blue.800"},
            },
        },
        "border": {"base": "$hue.neutral.600"},
        "scrollbar": {"base": "$hue.neutral.600"},
        "diff": {
            "text": {
                "added": "$hue.green.300",
                "removed": "$hue.red.300",
                "context": "$hue.neutral.400",
                "hunkHeader": "$hue.purple.300",
            },
            "background": {
                "added": "$hue.green.800",
                "removed": "$hue.red.800",
                "context": "$hue.neutral.700",
            },
            "highlight": {
                "added": "$hue.green.700",
                "removed": "$hue.red.700",
            },
            "lineNumber": {
                "text": "$hue.neutral.500",
                "background": {
                    "added": "$hue.green.800",
                    "removed": "$hue.red.800",
                },
            },
        },
        "syntax": {
            "comment": "$hue.neutral.500",
            "keyword": "$hue.purple.300",
            "function": "$hue.blue.300",
            "variable": "$hue.neutral.100",
            "string": "$hue.green.300",
            "number": "$hue.orange.300",
            "type": "$hue.cyan.300",
            "operator": "$hue.neutral.300",
            "punctuation": "$hue.neutral.400",
        },
        "markdown": {
            "text": "$hue.neutral.200",
            "heading": "$hue.blue.300",
            "link": "$hue.cyan.300",
            "linkText": "$hue.cyan.300",
            "code": "$hue.green.300",
            "blockQuote": "$hue.neutral.400",
            "emphasis": "$hue.purple.300",
            "strong": "$hue.blue.200",
            "horizontalRule": "$hue.neutral.500",
            "listItem": "$hue.blue.300",
            "listEnumeration": "$hue.purple.300",
            "image": "$hue.purple.300",
            "imageText": "$hue.purple.300",
            "codeBlock": "$hue.neutral.200",
        },
    }

    return {
        "$schema": "https://opencode.ai/theme.json",
        "base": base,
        "dark": {"hue": hue},
    }


def main():
    palette = json.load(open(sys.argv[1]))
    theme = build(palette)
    with open(sys.argv[2], "w") as f:
        json.dump(theme, f, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
