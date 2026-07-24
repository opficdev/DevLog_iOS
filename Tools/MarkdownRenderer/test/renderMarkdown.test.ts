import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

import { renderMarkdown } from "../src/renderMarkdown.ts";

test("CommonMark 기본 문법을 HTML로 변환한다", () => {
  const html = renderMarkdown(`
# 제목

**강조**

> 인용

\`inline\`

\`\`\`swift
let value = 1
\`\`\`
`);

  assert.match(html, /<h1>제목<\/h1>/);
  assert.match(html, /<strong>강조<\/strong>/);
  assert.match(html, /<blockquote>/);
  assert.match(html, /<code>inline<\/code>/);
  assert.match(html, /<code class="language-swift">let value = 1\n<\/code>/);
});

test("GFM 표와 취소선, 자동 링크, 각주, 작업 목록을 변환한다", () => {
  const html = renderMarkdown(`
~~취소~~

https://example.com

| 항목 | 값 |
| --- | --- |
| A | B |

- [x] 완료

각주[^1]

[^1]: 설명
`);

  assert.match(html, /<del>취소<\/del>/);
  assert.match(html, /<a href="https:\/\/example.com">https:\/\/example.com<\/a>/);
  assert.match(html, /<table>/);
  assert.match(html, /type="checkbox" checked disabled/);
  assert.match(html, /data-footnote-ref/);
  assert.match(html, /data-footnotes/);
});

test("각주 링크와 이동 대상 ID를 일치시킨다", () => {
  const html = renderMarkdown(`
각주[^1]

[^1]: 설명
`);
  const referenceMatch = html.match(
    /<a href="#([^"]+)"[^>]*data-footnote-ref/
  );
  const backReferenceMatch = html.match(
    /<a href="#([^"]+)"[^>]*data-footnote-backref/
  );

  assert.notEqual(referenceMatch, null);
  assert.notEqual(backReferenceMatch, null);
  assert.ok(html.includes(`id="${referenceMatch?.[1]}"`));
  assert.ok(html.includes(`id="${backReferenceMatch?.[1]}"`));
});

test("raw HTML과 위험한 URL scheme을 제거한다", () => {
  const html = renderMarkdown(`
<script>alert("xss")</script>

<img src="x" onerror="alert('xss')">

[스크립트](javascript:alert('xss'))

[파일](file:///private/data)

[웹](https://example.com)

[메일](mailto:test@example.com)
`);

  assert.doesNotMatch(html, /<script/i);
  assert.doesNotMatch(html, /onerror/i);
  assert.doesNotMatch(html, /javascript:/i);
  assert.doesNotMatch(html, /file:/i);
  assert.match(html, /href="https:\/\/example.com"/);
  assert.match(html, /href="mailto:test@example.com"/);
});

test("HTTPS 이미지만 원격 이미지로 유지한다", () => {
  const html = renderMarkdown(`
![HTTPS](https://example.com/image.png)

![HTTP](http://example.com/image.png)

![스크립트](javascript:alert('xss'))

![파일](file:///private/image.png)
`);

  assert.match(html, /src="https:\/\/example.com\/image.png"/);
  assert.doesNotMatch(html, /src="http:\/\/example.com\/image.png"/);
  assert.doesNotMatch(html, /javascript:/i);
  assert.doesNotMatch(html, /file:/i);
});

test("renderer 문서는 HTTPS 이미지 외 원격 자원과 임의의 inline 실행을 차단한다", () => {
  const document = readFileSync(
    new URL("../src/index.html", import.meta.url),
    "utf8"
  );

  assert.match(document, /default-src 'none'/);
  assert.match(document, /script-src 'self'/);
  assert.match(document, /style-src 'self' 'nonce-devlog-renderer'/);
  assert.match(document, /img-src https: data:/);
  assert.match(document, /connect-src 'none'/);
  assert.doesNotMatch(document, /unsafe-inline/);
  assert.doesNotMatch(document, /img-src[^;]*http:/);
});

test("renderer 문서는 세로 스크롤을 허용하고 가로 overflow만 숨긴다", () => {
  const stylesheet = readFileSync(
    new URL("../src/renderer.css", import.meta.url),
    "utf8"
  );
  const pageRule = stylesheet.match(/html,\s*body\s*\{([^}]*)\}/s);
  const markdownBodyRule = stylesheet.match(/\.markdown-body\s*\{([^}]*)\}/s);

  assert.notEqual(pageRule, null);
  assert.match(pageRule?.[1] ?? "", /overflow-x:\s*hidden/);
  assert.doesNotMatch(pageRule?.[1] ?? "", /overflow:\s*hidden/);
  assert.notEqual(markdownBodyRule, null);
  assert.match(markdownBodyRule?.[1] ?? "", /padding:\s*0 16px/);
  assert.doesNotMatch(stylesheet, /todo-reference-item/);
});
