import type { Element } from "hast";
import type { BlockContent, Code, List, ListItem, Root } from "mdast";
import type { Handler } from "mdast-util-to-hast";
import type { Plugin } from "unified";
import type { Node } from "unist";
import { visit } from "unist-util-visit";

import type { TodoReferences } from "./types.ts";

interface TodoReferenceNode extends Node {
  type: "todoReference";
  number: number;
}

declare module "mdast" {
  interface BlockContentMap {
    todoReference: TodoReferenceNode;
  }

  interface RootContentMap {
    todoReference: TodoReferenceNode;
  }
}

interface TodoReferencePluginOptions {
  references?: TodoReferences;
}

const todoReferencePattern = /^refs[ \t]+#([0-9]+)$/;
const legacyTodoReferencePattern =
  /^[ \t]*-[ \t]+refs[ \t]+#([0-9]+)[ \t]*$/;
const indentedCodePattern = /^(?: {4}|\t)/;

export const todoReferencePlugin: Plugin<
  [options?: TodoReferencePluginOptions],
  Root
> = (options = {}) => {
  const references =
    options.references !== null && typeof options.references === "object"
      ? options.references
      : {};
  const referenceNumbers = new Set(Object.keys(references).map(Number));

  return (tree, file) => {
    const source = String(file);

    visit(tree, "code", (node, index, parent) => {
      if (
        typeof index !== "number" ||
        (parent?.type !== "root" &&
          parent?.type !== "blockquote" &&
          parent?.type !== "listItem") ||
        !isIndentedCode(node, source)
      ) {
        return;
      }

      const blocks = splitLegacyTodoReferences(node);

      if (blocks !== null) {
        parent.children.splice(index, 1, ...blocks);
      }
    });

    visit(tree, "listItem", (node, index, parent) => {
      if (
        parent?.type !== "list" ||
        parent.ordered !== false ||
        typeof index !== "number" ||
        node.checked !== null ||
        node.children.length !== 1
      ) {
        return;
      }

      const paragraph = node.children[0];

      if (
        paragraph.type !== "paragraph" ||
        paragraph.children.length !== 1 ||
        paragraph.children[0].type !== "text"
      ) {
        return;
      }

      const match = todoReferencePattern.exec(paragraph.children[0].value);

      if (match === null) { return; }

      const number = Number(match[1]);

      if (!referenceNumbers.has(number)) { return; }

      node.children = [
        {
          type: "todoReference",
          number
        }
      ];
    });
  };
};

function isIndentedCode(node: Code, source: string) {
  const startOffset = node.position?.start.offset;
  const endOffset = node.position?.end.offset;

  if (typeof startOffset !== "number" || typeof endOffset !== "number") {
    return false;
  }

  const lineStartOffset = source.lastIndexOf("\n", startOffset - 1) + 1;
  const linePrefix = source.slice(lineStartOffset, startOffset);

  if (/[^ \t]/.test(linePrefix)) {
    return false;
  }

  return indentedCodePattern.test(source.slice(startOffset, endOffset));
}

function splitLegacyTodoReferences(node: Code) {
  const blocks = new Array<BlockContent>();
  let codeLines = new Array<string>();
  let referenceItems = new Array<ListItem>();
  let hasReference = false;

  const flushCode = () => {
    if (codeLines.length === 0) {
      return;
    }

    blocks.push({
      type: "code",
      lang: node.lang,
      meta: node.meta,
      value: codeLines.join("\n")
    });
    codeLines = [];
  };

  const flushReferences = () => {
    if (referenceItems.length === 0) {
      return;
    }

    blocks.push({
      type: "list",
      ordered: false,
      start: null,
      spread: false,
      children: referenceItems
    } satisfies List);
    referenceItems = [];
  };

  for (const line of node.value.split("\n")) {
    const match = legacyTodoReferencePattern.exec(line);

    if (match === null) {
      flushReferences();
      codeLines.push(line);
      continue;
    }

    flushCode();
    hasReference = true;
    referenceItems.push({
      type: "listItem",
      checked: null,
      spread: false,
      children: [
        {
          type: "paragraph",
          children: [
            {
              type: "text",
              value: `refs #${match[1]}`
            }
          ]
        }
      ]
    });
  }

  flushCode();
  flushReferences();

  return hasReference ? blocks : null;
}

export const todoReferenceHandler: Handler = (
  _state,
  node: TodoReferenceNode
) => {
  const number = String(node.number);

  return {
    type: "element",
    tagName: "button",
    properties: {
      type: "button",
      className: ["todo-reference"],
      dataTodoReferenceNumber: number
    },
    children: [
      {
        type: "text",
        value: `refs #${number}`
      }
    ]
  } satisfies Element;
};
