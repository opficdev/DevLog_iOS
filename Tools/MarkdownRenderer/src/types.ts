export interface TodoReference {
  color?: string;
  iconDataURL?: string;
  title?: string;
}

export type TodoReferences = Record<string, TodoReference>;

export interface RenderMarkdownPayload {
  colorScheme?: unknown;
  fontSize?: unknown;
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
