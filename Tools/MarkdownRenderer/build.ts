import { copyFile, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";

import { build } from "esbuild";

const rendererDirectory = fileURLToPath(new URL(".", import.meta.url));
const outputDirectory = fileURLToPath(
  new URL(
    "../../Application/Presentation/PresentationShared/Resources/MarkdownRenderer/",
    import.meta.url
  )
);

await mkdir(outputDirectory, { recursive: true });

await Promise.all([
  build({
    entryPoints: [`${rendererDirectory}src/index.ts`],
    outfile: `${outputDirectory}/renderer.js`,
    bundle: true,
    charset: "utf8",
    format: "iife",
    legalComments: "eof",
    minify: true,
    platform: "browser",
    sourcemap: false,
    target: ["safari17"]
  }),
  build({
    entryPoints: [`${rendererDirectory}src/renderer.css`],
    outfile: `${outputDirectory}/renderer.css`,
    bundle: true,
    charset: "utf8",
    legalComments: "eof",
    minify: true,
    sourcemap: false,
    target: ["safari17"]
  }),
  copyFile(
    `${rendererDirectory}src/index.html`,
    `${outputDirectory}/index.html`
  )
]);
