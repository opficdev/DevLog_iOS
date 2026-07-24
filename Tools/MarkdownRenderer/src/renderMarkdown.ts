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
  todoReferenceHandler,
  todoReferencePlugin
} from "./todoReferencePlugin.ts";
import type { TodoReferences } from "./types.ts";

const sanitizeSchema: SanitizeSchema = {
  ...defaultSchema,
  clobberPrefix: "",
  attributes: {
    ...defaultSchema.attributes,
    button: [
      ...(defaultSchema.attributes?.button ?? []),
      ["className", "todo-reference"],
      ["type", "button"],
      "dataTodoReferenceNumber"
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
  references: TodoReferences = {}
) {
  const source = typeof markdown === "string" ? markdown : "";

  const file = unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(todoReferencePlugin, { references })
    .use(remarkRehype, {
      handlers: {
        todoReference: todoReferenceHandler
      }
    })
    .use(rehypeSanitize, sanitizeSchema)
    .use(rehypeStringify)
    .processSync(source);

  return String(file);
}
