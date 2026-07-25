import type { Element } from "hast";
import type { Root } from "mdast";
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

export const todoReferencePlugin: Plugin<
  [options?: TodoReferencePluginOptions],
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
