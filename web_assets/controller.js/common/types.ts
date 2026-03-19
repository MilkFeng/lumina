import type { QuadTree, RectLike, QuadTreeItem } from './quad_tree';

// ─── Primitive Types ─────────────────────────────────────────────────

export type FrameSlot = 'prev' | 'curr' | 'next';

export type Direction = 'next' | 'prev';

// ─── Config / Theme ──────────────────────────────────────────────────

export interface ReaderPadding {
  top: number;
  left: number;
}

export interface Color {
  r: number;
  g: number;
  b: number;
  a?: number;
}

export function colorToHex(color: Color): string {
  function padStart(value: string, targetLength: number, padString: string): string {
    while (value.length < targetLength) {
      value = padString + value;
    }
    return value;
  }

  const r = padStart(color.r.toString(16), 2, '0');
  const g = padStart(color.g.toString(16), 2, '0');
  const b = padStart(color.b.toString(16), 2, '0');
  const a = color.a !== undefined ? padStart(Math.round(color.a * 255).toString(16), 2, '0') : '';
  return '#' + r + g + b + a;
}

export const WhiteColor: Color = { r: 255, g: 255, b: 255, a: 1 };
export const BlackColor: Color = { r: 0, g: 0, b: 0, a: 1 };

/// Parses a CSS color string (hex or rgb/rgba) into a Color object. Returns null if parsing fails.
export function parseColorString(colorStr: string): Color | null {
  const str = colorStr.trim().toLowerCase();

  if (str === 'transparent') {
    return { r: 0, g: 0, b: 0, a: 0 };
  }

  const hexMatch = str.match(/^#?([a-f\d]{3,8})$/);
  if (hexMatch) {
    let hex = hexMatch[1];
    if (hex.length === 3 || hex.length === 4) {
      hex = hex.split('').map(char => char + char).join('');
    }

    if (hex.length === 6 || hex.length === 8) {
      const r = parseInt(hex.substring(0, 2), 16);
      const g = parseInt(hex.substring(2, 4), 16);
      const b = parseInt(hex.substring(4, 6), 16);
      if (hex.length === 8) {
        const a = Math.round((parseInt(hex.substring(6, 8), 16) / 255) * 100) / 100;
        return { r, g, b, a };
      }
      return { r, g, b };
    }
  }

  const rgbMatch = str.match(/^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*([\d.]+))?\s*\)$/);
  if (rgbMatch) {
    const r = parseInt(rgbMatch[1], 10);
    const g = parseInt(rgbMatch[2], 10);
    const b = parseInt(rgbMatch[3], 10);

    if (r > 255 || g > 255 || b > 255) {
      return null;
    }

    if (rgbMatch[4] !== undefined) {
      const a = parseFloat(rgbMatch[4]);
      if (a >= 0 && a <= 1) {
        return { r, g, b, a };
      }
      return null;
    }

    return { r, g, b };
  }

  return null;
}

export interface ReaderTheme {
  zoom: number;
  surfaceColor: Color;
  onSurfaceColor: Color;
  shouldOverrideTextColor: boolean;
  primaryColor: Color;
  primaryContainerColor: Color;
  onSurfaceVariantColor: Color;
  outlineVariantColor: Color;
  surfaceContainerColor: Color;
  surfaceContainerHighColor: Color;
  overrideFontFamily?: boolean;
  fontFileName?: string | null;
}

export interface ReaderConfig {
  safeWidth: number;
  safeHeight: number;
  direction: number;
  padding: ReaderPadding;
  theme: ReaderTheme;

  paginationCss: string;
}

// ─── State ───────────────────────────────────────────────────────────

export interface InteractionItem extends QuadTreeItem {
  type: string;
  priority: number;
  rect: RectLike;
  data: string;
}

export interface ReaderState {
  anchors: Record<FrameSlot, string[]>;
  properties: Record<FrameSlot, string[]>;
  quadTree: QuadTree<InteractionItem> | null;
  config: ReaderConfig;
}

// ─── Method Params ───────────────────────────────────────────────────

export interface ThemeUpdate {
  padding: ReaderPadding;
  theme: ReaderTheme;
}

// ─── Internal Helpers ────────────────────────────────────────────────

/** WebKit-specific CSS properties not in the standard CSSStyleDeclaration */
export interface WebKitCSSStyle extends CSSStyleDeclaration {
  webkitColumnBreakBefore: string;
  webkitColumnBreakAfter: string;
}
