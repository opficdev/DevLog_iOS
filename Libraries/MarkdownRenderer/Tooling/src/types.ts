export interface MarkdownReference {
  color?: string;
  iconDataURL?: string;
  title?: string;
}

export type MarkdownReferences = Record<string, MarkdownReference>;

export interface RenderMarkdownPayload {
  colorScheme?: unknown;
  fontSize?: unknown;
  languageCode?: unknown;
  markdown?: unknown;
  references?: unknown;
}

interface ScriptMessageHandler {
  postMessage(payload: unknown): void;
}

declare global {
  interface Window {
    renderMarkdown(payload?: RenderMarkdownPayload): void;
    webkit?: {
      messageHandlers?: Record<string, ScriptMessageHandler | undefined>;
    };
  }
}
