import { renderMarkdown } from "./renderMarkdown.ts";
import type {
  RenderMarkdownPayload,
  TodoReferences
} from "./types.ts";

const documentElement = document.documentElement;
const contentElement = document.getElementById(
  "markdown-content"
) as HTMLElement;
const dynamicStyleElement = document.getElementById(
  "renderer-dynamic-style"
) as HTMLStyleElement;

function postMessage(name: string, payload: unknown) {
  const handler = window.webkit?.messageHandlers?.[name];

  if (typeof handler?.postMessage === "function") {
    handler.postMessage(payload);
  }
}

function referenceStyleRules(references: TodoReferences) {
  const rules = [];

  for (const [number, reference] of Object.entries(references)) {
    if (!/^[0-9]+$/.test(number) || typeof reference?.color !== "string") {
      continue;
    }

    const color = reference.color.trim();

    if (!/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(color)) {
      continue;
    }

    rules.push(
      `.todo-reference[data-todo-reference-number="${number}"] .todo-reference-icon{background-color:${color}}`
    );
  }

  return rules;
}

function hydrateTodoReferences(references: TodoReferences) {
  const buttons = contentElement.querySelectorAll<HTMLButtonElement>(
    ".todo-reference[data-todo-reference-number]"
  );

  for (const button of buttons) {
    const number = button.dataset.todoReferenceNumber;

    if (number === undefined) {
      continue;
    }

    const reference = references[number];

    if (reference === undefined) {
      continue;
    }

    const prefix = document.createElement("span");
    prefix.className = "todo-reference-prefix";
    prefix.textContent = "refs";

    const icon = document.createElement("span");
    icon.className = "todo-reference-icon";

    if (
      typeof reference.iconDataURL === "string" &&
      reference.iconDataURL.startsWith("data:image/png;base64,")
    ) {
      const image = document.createElement("img");
      image.alt = "";
      image.src = reference.iconDataURL;
      icon.append(image);
    }

    const title = document.createElement("span");
    title.className = "todo-reference-title";
    title.textContent = reference.title ?? "";

    const numberLabel = document.createElement("span");
    numberLabel.className = "todo-reference-number";
    numberLabel.textContent = `#${number}`;

    button.replaceChildren(prefix, icon, title, numberLabel);
    button.addEventListener("click", () => {
      postMessage("todoReference", {
        number: Number(number)
      });
    });
  }
}

function configureLinks() {
  for (const link of contentElement.querySelectorAll<HTMLAnchorElement>(
    "a[href]"
  )) {
    const url = link.getAttribute("href");

    if (url === null || url.startsWith("#")) {
      continue;
    }

    link.addEventListener("click", (event) => {
      event.preventDefault();
      postMessage("externalLink", { url });
    });
  }
}

window.renderMarkdown = (payload: RenderMarkdownPayload = {}) => {
  const markdown = typeof payload.markdown === "string" ? payload.markdown : "";
  const references =
    payload.references !== null && typeof payload.references === "object"
      ? (payload.references as TodoReferences)
      : {};
  const colorScheme = payload.colorScheme === "dark" ? "dark" : "light";
  const languageCode =
    typeof payload.languageCode === "string" && payload.languageCode !== ""
      ? payload.languageCode
      : "und";
  const requestedFontSize = payload.fontSize;
  const fontSize =
    typeof requestedFontSize === "number" &&
    Number.isFinite(requestedFontSize) &&
    0 < requestedFontSize
      ? Math.min(Math.max(requestedFontSize, 8), 80)
      : 17;

  documentElement.dataset.colorScheme = colorScheme;
  documentElement.lang = languageCode;
  dynamicStyleElement.textContent = [
    `:root{--markdown-font-size:${fontSize}px}`,
    ...referenceStyleRules(references)
  ].join("\n");
  contentElement.innerHTML = renderMarkdown(markdown, references);

  hydrateTodoReferences(references);
  configureLinks();
};
