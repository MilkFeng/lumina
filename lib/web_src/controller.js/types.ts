import type { QuadTree, RectLike, QuadTreeItem } from './quad_tree';

// ─── Primitive Types ─────────────────────────────────────────────────

export type FrameSlot = 'prev' | 'curr' | 'next';

// ─── Config / Theme ──────────────────────────────────────────────────

export interface ReaderPadding {
    top: number;
    left: number;
    right: number;
    bottom: number;
}

export interface ReaderTheme {
    zoom: number;
    paginationCss: string;
    variableCss: string;
    surfaceColor: string;
    onSurfaceColor: string;
    shouldOverrideTextColor: boolean;
    primaryColor: string;
    primaryContainerColor: string;
    onSurfaceVariantColor: string;
    outlineVariantColor: string;
    surfaceContainerColor: string;
    surfaceContainerHighColor: string;
    overrideFontFamily?: boolean;
    fontFileName?: string | null;
    overridePrimaryColor?: string | null;
}

export interface ReaderConfig {
    safeWidth: number;
    safeHeight: number;
    direction: number;
    padding: ReaderPadding;
    theme: ReaderTheme;
}

// ─── State ───────────────────────────────────────────────────────────

export interface InteractionItem extends QuadTreeItem {
    type: string;
    rect: RectLike;
    data: string;
}

export interface ReaderState {
    frames: Record<FrameSlot, number>;
    anchors: Record<FrameSlot, string[]>;
    quadTree: QuadTree<InteractionItem> | null;
    config: ReaderConfig;
}

// ─── Method Params ───────────────────────────────────────────────────

export interface InitConfig {
    safeWidth?: number;
    safeHeight?: number;
    direction?: number;
    padding?: Partial<ReaderPadding>;
    theme: ReaderTheme;
}

export interface ThemeUpdate {
    zoom: number;
    padding: ReaderPadding;
    shouldOverrideTextColor: boolean;
    fontFileName?: string | null;
    overrideFontFamily?: boolean;
    overridePrimaryColor?: string | null;
    primaryColor: string;
    primaryContainerColor: string;
    surfaceColor: string;
    onSurfaceColor: string;
    onSurfaceVariantColor: string;
    outlineVariantColor: string;
    surfaceContainerColor: string;
    surfaceContainerHighColor: string;
}

// ─── Internal Helpers ────────────────────────────────────────────────

/** WebKit-specific CSS properties not in the standard CSSStyleDeclaration */
export interface WebKitCSSStyle extends CSSStyleDeclaration {
    webkitColumnBreakBefore: string;
    webkitColumnBreakAfter: string;
}
