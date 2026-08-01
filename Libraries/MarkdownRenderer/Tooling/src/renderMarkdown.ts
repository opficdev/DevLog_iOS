import rehypeHighlight from "rehype-highlight";
import rehypeSanitize, {
  defaultSchema,
  type Options as SanitizeSchema
} from "rehype-sanitize";
import rehypeStringify from "rehype-stringify";
import remarkGfm from "remark-gfm";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import { unified } from "unified";

import {
  referenceHandler,
  referencePlugin
} from "./referencePlugin.ts";
import { normalizeReferences } from "./referenceNormalizer.ts";
import type { MarkdownReferences } from "./types.ts";

const highlightTokenClassNames = [
  "hljs-addition",
  "hljs-attr",
  "hljs-attribute",
  "hljs-built_in",
  "hljs-bullet",
  "hljs-char",
  "hljs-code",
  "hljs-comment",
  "hljs-deletion",
  "hljs-doctag",
  "hljs-emphasis",
  "hljs-formula",
  "hljs-keyword",
  "hljs-link",
  "hljs-literal",
  "hljs-meta",
  "hljs-name",
  "hljs-number",
  "hljs-operator",
  "hljs-params",
  "hljs-property",
  "hljs-punctuation",
  "hljs-quote",
  "hljs-regexp",
  "hljs-section",
  "hljs-selector-attr",
  "hljs-selector-class",
  "hljs-selector-id",
  "hljs-selector-pseudo",
  "hljs-selector-tag",
  "hljs-string",
  "hljs-strong",
  "hljs-subst",
  "hljs-symbol",
  "hljs-tag",
  "hljs-template-tag",
  "hljs-template-variable",
  "hljs-title",
  "hljs-type",
  "hljs-variable"
] as const;

const sanitizeSchema: SanitizeSchema = {
  ...defaultSchema,
  clobberPrefix: "",
  attributes: {
    ...defaultSchema.attributes,
    button: [
      ...(defaultSchema.attributes?.button ?? []),
      ["className", "markdown-reference"],
      ["type", "button"],
      "dataReferenceNumber"
    ],
    code: [["className", "hljs", /^language-./]],
    span: [
      ...(defaultSchema.attributes?.span ?? []),
      ["className", ...highlightTokenClassNames]
    ]
  },
  protocols: {
    ...defaultSchema.protocols,
    href: ["http", "https", "mailto"],
    src: ["https"]
  },
  tagNames: [...(defaultSchema.tagNames ?? []), "button"]
};

export function renderMarkdown(
  markdown: unknown,
  references: MarkdownReferences = {}
) {
  const source = normalizeReferences(
    typeof markdown === "string" ? markdown : ""
  );

  const file = unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(referencePlugin, { references })
    .use(remarkRehype, {
      handlers: {
        reference: referenceHandler
      }
    })
    .use(rehypeHighlight)
    .use(rehypeSanitize, sanitizeSchema)
    .use(rehypeStringify)
    .processSync(source);

  return String(file);
}
