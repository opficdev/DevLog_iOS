import assert from "node:assert/strict";
import test from "node:test";

import { normalizeTodoReferences } from "../src/todoReferenceNormalizer.ts";

test("Todo 참조 원문을 표준 문법으로 정규화한다", () => {
  const normalized = normalizeTodoReferences(`
- refs #042
-     refs #42
    before
        - refs #7
    after
`);

  assert.equal(
    normalized,
    `
- refs #42
- refs #42
    before
- refs #7
<!-- todo-reference-boundary -->
    after
`
  );
});

test("fenced code 안의 Todo 참조 원문은 변경하지 않는다", () => {
  const normalized = normalizeTodoReferences(`
\`\`\`
- refs #042
\`\`\`

- \`\`\`
  - refs #42
  \`\`\`

- refs #042
`);

  assert.equal(
    normalized,
    `
\`\`\`
- refs #042
\`\`\`

- \`\`\`
  - refs #42
  \`\`\`

- refs #42
`
  );
});
