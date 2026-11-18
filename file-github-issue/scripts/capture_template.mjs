// Evidence capture template for the file-github-issue skill.
//
// Copy this file into the CAPTURE_DIR printed by setup_capture.sh (so that
// `playwright`, `gifenc` and `pngjs` resolve), edit ONLY the FLOW section, and run:
//
//   cd "$CAPTURE_DIR" && BASE_URL="https://example.com" OUT_DIR="/abs/path/out" node capture.mjs
//
// Sign-in details, if needed, come from EVIDENCE_USER / EVIDENCE_PASSWORD so they
// never end up in a file. The run produces, in OUT_DIR:
//   before.png, after.png  - the before/after pair (same viewport, same page)
//   steps.gif              - every step with its caption above it; plays inside the issue
//   recording.webm         - the full run as a video (linked from the issue)
//   facts.txt              - what the page actually said at key moments
import { chromium } from 'playwright';
import gifenc from 'gifenc'; // CommonJS package: import the default, then pick
import pngjs from 'pngjs';
const { GIFEncoder, quantize, applyPalette } = gifenc;
const { PNG } = pngjs;
import fs from 'node:fs';
import path from 'node:path';

const BASE_URL = process.env.BASE_URL || 'about:blank';
const OUT_DIR = path.resolve(process.env.OUT_DIR || './evidence');
const USER = process.env.EVIDENCE_USER || '';
const PASSWORD = process.env.EVIDENCE_PASSWORD || '';
const VIEWPORT = { width: 1024, height: 640 }; // the same for every frame and both stills
const HOLD_MS = 1400;                           // how long each GIF frame stays on screen

fs.mkdirSync(OUT_DIR, { recursive: true });
const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: VIEWPORT,
  deviceScaleFactor: 1,
  recordVideo: { dir: path.join(OUT_DIR, '.video'), size: VIEWPORT },
});
const page = await context.newPage();
// A second, unrecorded page that lays each GIF frame out as: caption bar on top,
// screenshot underneath. The caption never covers anything in the app itself.
const BAR = 52;
const composerContext = await browser.newContext({
  viewport: { width: VIEWPORT.width, height: VIEWPORT.height + BAR }, deviceScaleFactor: 1,
});
const composer = await composerContext.newPage();
const frames = [];
const facts = [];
let currentCaption = '';

// ---- helpers (no need to edit) ----------------------------------------------------

/** Draw a red outline around the thing about to be clicked or typed into. */
async function highlight(locator, on = true) {
  await locator.evaluate((el, on) => {
    el.style.outline = on ? '4px solid #e5372b' : '';
    el.style.outlineOffset = on ? '3px' : '';
  }, on).catch(() => {});
}

/** Add the current screen, with the current caption above it, to the GIF. */
async function frame(holdMs = HOLD_MS) {
  if (page.url() === 'about:blank') return; // nothing to show yet
  const shot = (await page.screenshot()).toString('base64');
  const caption = currentCaption.replace(/[&<>"]/g, (c) => `&#${c.charCodeAt(0)};`);
  await composer.setContent(
    `<body style="margin:0;background:#14181f">
       <div style="height:${BAR}px;box-sizing:border-box;padding:0 18px;display:flex;align-items:center;
                   color:#fff;font:600 20px system-ui,'Segoe UI',sans-serif">${caption}</div>
       <img style="display:block" src="data:image/png;base64,${shot}"></body>`);
  await composer.locator('img').evaluate((img) => img.decode());
  frames.push({ buf: await composer.screenshot(), delay: holdMs });
}

/**
 * One user-visible step: caption + outline -> frame -> do it -> frame of the result.
 *   await step('Step 2: Click "Save"', () => save.click(), { target: save });
 * `settle` waits for the result to appear, e.g. { settle: () => page.getByText('Saved').waitFor() }
 */
async function step(caption, action, { target, settle } = {}) {
  currentCaption = caption;
  if (target) { await target.waitFor({ state: 'visible' }); await highlight(target); }
  await frame();
  if (target) await highlight(target, false);
  if (action) await action();
  if (settle) await settle();
  else await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
  await frame();
}

/** Save a clean still of the page as before.png / after.png (same viewport every time). */
async function snap(name) {
  await page.screenshot({ path: path.join(OUT_DIR, `${name}.png`) });
}

/** Record what the page actually says, so the pictures can be checked. */
async function fact(label, value) {
  const line = `${label}: ${JSON.stringify(value)}`;
  facts.push(line);
  console.log('  ' + line);
}

async function finish() {
  if (frames.length) frames[frames.length - 1].delay = 3500; // linger on the result
  const gif = GIFEncoder();
  frames.forEach((f, i) => {
    const png = PNG.sync.read(f.buf);
    const palette = quantize(png.data, 256);
    gif.writeFrame(applyPalette(png.data, palette), png.width, png.height,
      { palette, delay: f.delay, ...(i === 0 ? { repeat: 0 } : {}) });
  });
  gif.finish();
  fs.writeFileSync(path.join(OUT_DIR, 'steps.gif'), gif.bytes());
  fs.writeFileSync(path.join(OUT_DIR, 'facts.txt'), facts.join('\n') + '\n');
  const video = page.video();
  await context.close();
  await composerContext.close();
  if (video) fs.renameSync(await video.path(), path.join(OUT_DIR, 'recording.webm'));
  fs.rmSync(path.join(OUT_DIR, '.video'), { recursive: true, force: true });
  await browser.close();
  for (const f of fs.readdirSync(OUT_DIR)) {
    const kb = Math.round(fs.statSync(path.join(OUT_DIR, f)).size / 1024);
    console.log(`WROTE ${path.join(OUT_DIR, f)} (${kb} KB)`);
  }
}

// ---- FLOW: edit this part for each issue -------------------------------------------
// Prefer getByRole / getByLabel / getByText so the steps read like the issue's steps.
// Wait on real things (an element appearing) rather than fixed timeouts.
try {
  await step('Step 1: Open the page', () => page.goto(BASE_URL));

  // Optional sign-in, e.g.:
  // const email = page.getByLabel('Email');
  // await step('Step 2: Log in', async () => {
  //   await email.fill(USER); await page.getByLabel('Password').fill(PASSWORD);
  //   await page.getByRole('button', { name: 'Log in' }).click();
  // }, { target: email });

  await snap('before');   // the moment right before the action that goes wrong

  // const save = page.getByRole('button', { name: 'Save' });
  // await step('Step 3: Click "Save"', () => save.click(), { target: save });

  await snap('after');    // the result: the problem is visible here
  // await fact('Message shown', await page.getByRole('alert').allTextContents());
} finally {
  await finish();
}
