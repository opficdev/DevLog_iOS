import assert from "node:assert/strict";
import test from "node:test";

import { normalizeReferences } from "../src/referenceNormalizer.ts";

test("참조 원문을 표준 문법으로 정규화한다", () => {
  const normalized = normalizeReferences(`
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
<!-- reference-boundary -->
    after
`
  );
});

test("fenced code 안의 참조 원문은 변경하지 않는다", () => {
  const normalized = normalizeReferences(`
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
