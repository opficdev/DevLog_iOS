import type { Element } from "hast";
import type { Root } from "mdast";
import type { Handler } from "mdast-util-to-hast";
import type { Plugin } from "unified";
import type { Node } from "unist";
import { visit } from "unist-util-visit";

import type { MarkdownReferences } from "./types.ts";

interface ReferenceNode extends Node {
  type: "reference";
  number: number;
}

declare module "mdast" {
  interface BlockContentMap {
    reference: ReferenceNode;
  }

  interface RootContentMap {
    reference: ReferenceNode;
  }
}

interface ReferencePluginOptions {
  references?: MarkdownReferences;
}

const referencePattern = /^refs[ \t]+#([0-9]+)$/;

export const referencePlugin: Plugin<
  [options?: ReferencePluginOptions],
  Root
> = (options = {}) => {
  const references =
    options.references !== null && typeof options.references === "object"
      ? options.references
      : {};
  const referenceNumbers = new Set(Object.keys(references).map(Number));

  return tree => {
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

      const match = referencePattern.exec(paragraph.children[0].value);

      if (match === null) { return; }

      const number = Number(match[1]);

      if (!referenceNumbers.has(number)) { return; }

      node.children = [
        {
          type: "reference",
          number
        }
      ];
    });
  };
};

export const referenceHandler: Handler = (
  _state,
  node: ReferenceNode
) => {
  const number = String(node.number);

  return {
    type: "element",
    tagName: "button",
    properties: {
      type: "button",
      className: ["markdown-reference"],
      dataReferenceNumber: number
    },
    children: [
      {
        type: "text",
        value: `refs #${number}`
      }
    ]
  } satisfies Element;
};
