import assert from "node:assert/strict";
import test from "node:test";

test("본문 높이 추적은 선택한 경우에만 동작하며 확대와 축소를 전달한다", async () => {
  const messages: { height: number }[] = [];
  let height = 240.5;
  let observing = false;
  let notifyResize = () => {};
  const content = {
    innerHTML: "",
    querySelectorAll: () => [],
    getBoundingClientRect: () => ({ height })
  };

  Object.assign(globalThis, {
    document: {
      documentElement: { dataset: {}, lang: "" },
      getElementById: (id: string) =>
        id === "markdown-content" ? content : { textContent: "" }
    },
    window: {
      webkit: {
        messageHandlers: {
          contentHeight: {
            postMessage: (message: { height: number }) => messages.push(message)
          }
        }
      }
    },
    ResizeObserver: class {
      constructor(callback: () => void) {
        notifyResize = callback;
      }
      observe() { observing = true; }
      disconnect() { observing = false; }
    }
  });

  await import("../src/index.ts");
  window.renderMarkdown({ markdown: "# 제목" });
  assert.equal(observing, false);
  assert.deepEqual(messages, []);

  window.renderMarkdown({ markdown: "# 제목", tracksContentHeight: true });
  assert.equal(observing, true);
  assert.deepEqual(messages, [{ height: 241 }]);
  notifyResize();
  assert.equal(messages.length, 1);

  // 이미지 로딩이나 줄바꿈으로 늘어난 높이를 반영한다.
  height = 900;
  notifyResize();
  assert.deepEqual(messages.at(-1), { height: 900 });

  // 짧은 본문으로 교체할 때 기존 viewport 높이에 고정되지 않는다.
  height = 80;
  window.renderMarkdown({ markdown: "짧은 본문", tracksContentHeight: true });
  assert.deepEqual(messages.at(-1), { height: 80 });

  height = 0;
  notifyResize();
  assert.deepEqual(messages.at(-1), { height: 1 });

  window.renderMarkdown({ markdown: "기본 스크롤" });
  assert.equal(observing, false);
  const count = messages.length;
  height = 400;
  notifyResize();
  assert.equal(messages.length, count);
});
