import assert from "node:assert/strict";
import test from "node:test";

import { renderMarkdown } from "../src/renderMarkdown.ts";

test("알려진 Todo 참조만 전용 요소로 변환한다", () => {
  const html = renderMarkdown(
    `
본문

- refs #42
- refs #7
`,
    {
      42: {
        title: "연결된 Todo"
      }
    }
  );

  assert.doesNotMatch(html, /todo-reference-item/);
  assert.match(
    html,
    /<button type="button" class="todo-reference" data-todo-reference-number="42">refs #42<\/button>/
  );
  assert.match(html, /<li>refs #7<\/li>/);
});

test("Todo 참조 문법이 아닌 항목은 변경하지 않는다", () => {
  const html = renderMarkdown(
    `
- ref #42
- refs 42

\`- refs #42\`

\`\`\`
- refs #42
\`\`\`
`,
    {
      42: {
        title: "연결된 Todo"
      }
    }
  );

  assert.doesNotMatch(html, /class="todo-reference"/);
  assert.match(html, /<li>ref #42<\/li>/);
  assert.match(html, /<li>refs 42<\/li>/);
  assert.match(html, /<code>- refs #42<\/code>/);
  assert.match(html, /<code>- refs #42\n<\/code>/);
});

test("같은 Todo 참조가 반복되면 각각 전용 요소로 변환한다", () => {
  const html = renderMarkdown(
    `
- refs #3
- refs #3
`,
    {
      3: {
        title: "반복 Todo"
      }
    }
  );

  assert.equal(html.match(/data-todo-reference-number="3"/g)?.length, 2);
});
