#!/usr/bin/env bash
# Colors matching noctalia's Catppuccin Mocha scheme (0xAARRGGBB)
# Values taken directly from Assets/ColorScheme/Catppuccin/Catppuccin.json

export ACCENT="0xffcba6f7"        # mPrimary    — mauve (active border, highlights)
export ON_ACCENT="0xff11111b"      # mOnPrimary  — crust
export SECONDARY="0xfffab387"      # mSecondary  — peach
export HOVER="0xff94e2d5"          # mHover      — teal
export ERROR="0xfff38ba8"          # mError      — red
export SURFACE="0xff1e1e2e"        # mSurface    — base
export ON_SURFACE="0xffcdd6f4"     # mOnSurface  — text
export SURFACE_VARIANT="0xff313244" # mSurfaceVariant — surface0
export ON_SURFACE_VARIANT="0xffa3b4eb" # mOnSurfaceVariant
export OUTLINE="0xff4c4f69"        # mOutline    — overlay1
export SHADOW="0xff11111b"         # mShadow     — crust
export INACTIVE="0xff585b70"       # inactive border color (from niri config)

# Semantic aliases used by items
export BAR_COLOR="${SURFACE}"
export ITEM_BG_COLOR="${SURFACE_VARIANT}"
export ACCENT_COLOR="${ACCENT}"
export ICON_COLOR="${ACCENT}"
export LABEL_COLOR="${ON_SURFACE}"
export MUTED_COLOR="${ON_SURFACE_VARIANT}"
export WARN_COLOR="${SECONDARY}"
export URGENT_COLOR="${ERROR}"
