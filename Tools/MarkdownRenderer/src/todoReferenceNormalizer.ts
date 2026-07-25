import type { Code } from "mdast";
import remarkParse from "remark-parse";
import { unified } from "unified";
import { visit } from "unist-util-visit";

interface SourceRange {
  start: number;
  end: number;
}

const todoReferenceLinePattern =
  /^([ \t]*)-[ \t]+refs[ \t]+#([0-9]+)[ \t]*(\r?)$/gm;
const todoReferenceBoundary = "<!-- todo-reference-boundary -->";
const fencePattern = /^(?:`{3,}|~{3,})/;

export function normalizeTodoReferences(source: string) {
  const fencedCodeRanges = makeFencedCodeRanges(source);
  let rangeIndex = 0;

  return source.replace(
    todoReferenceLinePattern,
    (
      line: string,
      leadingWhitespace: string,
      numberValue: string,
      carriageReturn: string,
      offset: number
    ) => {
      while (
        fencedCodeRanges[rangeIndex] !== undefined &&
        fencedCodeRanges[rangeIndex].end <= offset
      ) {
        rangeIndex += 1;
      }

      const range = fencedCodeRanges[rangeIndex];

      if (range !== undefined && range.start <= offset && offset < range.end) {
        return line;
      }

      const normalizedLine = `- refs #${Number(numberValue)}`;
      const hasFollowingLine = source[offset + line.length] === "\n";

      if (leadingWhitespace.length === 0 || !hasFollowingLine) {
        return `${normalizedLine}${carriageReturn}`;
      }

      const lineEnding = carriageReturn === "\r" ? "\r\n" : "\n";

      return `${normalizedLine}${lineEnding}${todoReferenceBoundary}${carriageReturn}`;
    }
  );
}

function makeFencedCodeRanges(source: string) {
  const tree = unified().use(remarkParse).parse(source);
  const ranges = new Array<SourceRange>();

  visit(tree, "code", (node: Code) => {
    const start = node.position?.start.offset;
    const end = node.position?.end.offset;

    if (
      typeof start !== "number" ||
      typeof end !== "number" ||
      !fencePattern.test(source.slice(start, end))
    ) {
      return;
    }

    ranges.push({ start, end });
  });

  return ranges;
}
