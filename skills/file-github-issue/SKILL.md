---
name: file-github-issue
description: File a GitHub issue as a Bug, Feature or Task, written in plain language anyone can understand, with Type, Title, Description, Pre-condition, Steps to Reproduce, Actual, Expected and Evidence. Captures before/after screenshots and a step-by-step GIF (or uses the user's own files), uploaded to a secret gist in the user's own GitHub account. Use this skill whenever the user asks to file, create, open, raise, log or report an issue, bug, feature request, task or ticket on GitHub, for example "file the issue", "file this in GitHub", "open an issue for this", "log this bug", "add a feature request", "create a task for this" or "make a ticket for this". Also use it when the user describes something broken, wanted or needing to be done and wants it recorded, or shares a screenshot or recording of a problem, even if they never say "GitHub issue". If it was already discussed earlier in the conversation, start from that instead of asking again.
---

# File a GitHub issue in plain language

The goal is an issue that a developer can act on without asking questions, and that a manager, tester or customer can read and understand. The person filing it may not be technical, so speak to them simply too.

## 1. Collect the facts

Work out what you already know from the conversation first. Ask only for what is missing, in short, friendly questions, a few at a time rather than a long form. You need:

- **Which repository** (`owner/repo`). If you're inside a git repo, `gh repo view --json nameWithOwner,isPrivate` tells you. Confirm it with the user rather than guessing.
- **Which type it is: Bug, Feature or Task.** Decide this from what they describe rather than asking, and show it in the preview so they can change it:

  | Type | Choose it when… | Examples |
  |---|---|---|
  | **Bug** | Something that should already work is broken, wrong or missing | "The Save button does nothing", "Prices show in the wrong currency" |
  | **Feature** | They want something new, or an existing thing made better, easier or clearer | "Add a dark mode", "Let me export to Excel", "The error message is confusing" |
  | **Task** | Work that needs doing where nothing is broken and the product itself doesn't change for users | "Update the help page screenshots", "Renew the SSL certificate", "Translate the settings page" |

  The quickest test: *does it work the way it was meant to?* No → **Bug**. Yes, but they want it to do more or work differently → **Feature**. It's a job to get done → **Task**. When a request could be read two ways (e.g. "the menu is hard to find" could be a Bug or a Feature), pick the closest and say why in one short line in the preview.
- **What went wrong** (or what they want), in their own words.
- **Where and how**: the page, screen or feature, and what they clicked or typed before it happened.
- **What they expected to happen instead.**
- **Anything needed beforehand** (logged in as admin, a plugin enabled, a certain browser or device, a specific setting). This becomes the Pre-condition.
- **Where to see it**: a web address you can open (then you can capture the evidence yourself, see step 3), or screenshots and recordings they already have.

## 2. Write it in plain language

Write for someone who has never seen the code:

- Short sentences and everyday words. Say "the page goes blank", not "a fatal render exception occurs". If a technical term really is needed (such as an error message they saw), quote it exactly but explain it in plain words too.
- **Title**: under about 70 characters, saying what and where. For a Bug, what is broken (*"Checkout button does nothing on the cart page"*, not *"Bug"* or *"JS error in cart.js"*). For a Feature, what should be possible (*"Allow exporting the order list to Excel"*). For a Task, the job to do (*"Update screenshots on the Getting Started help page"*).
- **Steps**: numbered, one action per step, in the order a person would do them, starting from a place anyone can reach (e.g. "Go to the website's home page"). Name buttons and menus exactly as they appear on screen, in **bold**.
- **Actual** and **Expected**: concrete and observable. Describe what you see, not guesses about the cause.
- Don't invent details the user didn't give. If something important is unknown (such as the browser), ask, or leave it out.

Use this exact structure for the body:

```markdown
## Type
<Bug, Feature or Task>

## Description
<1–3 sentences: what the problem is and why it matters to the person using it.>

## Pre-condition
<What must be true before starting, as a short list. Write "None" if nothing is needed.>

## Steps to Reproduce
1. <first action>
2. <next action>
3. ...

## Actual Result
<What actually happens.>

## Expected Result
<What should happen instead.>

## Evidence
<Before / After pair, step-by-step GIF, video link and facts, laid out as in step 3d. Or: "No screenshots or videos were provided.">
```

The title is passed separately to `gh issue create`, so don't repeat it in the body.

Keep the same sections for every type so issues always look familiar, but fill them in to suit the type:

| Section | Bug | Feature | Task |
|---|---|---|---|
| **Description** | What's broken and who it affects | What's wanted and why it would help | What needs doing and why |
| **Pre-condition** | What must be true to see the bug | What must be true to reach the spot | Access or info needed for the job, or "None" |
| **Steps to Reproduce** | The steps that make the bug happen | The steps to get to where the new thing would go | The steps of the work, or "Not applicable" |
| **Actual Result** | What wrongly happens | How it works today, or "This doesn't exist yet" | The current state |
| **Expected Result** | What should happen | How it should work once added | What "done" looks like |
| **Evidence** | Screenshots of the problem | Screenshots of the current screen, sketches or examples from elsewhere | Anything that shows the current state, or "None needed" |

## 3. Gather the evidence: before, after, and a step-by-step GIF

Good evidence lets someone *see* the problem without having to reproduce it. Aim for three things:

- **A Before / After pair**: two screenshots of the same screen, taken the same way. *Before* is the moment right before the step that goes wrong. *After* is the moment the problem is visible. Same page and same window size, so the only difference is what that step did. Otherwise they're just two unrelated pictures.
- **A step-by-step GIF**: each step captioned, playing right inside the issue.
- **A video** of the whole thing, linked from the issue.

What Before / After means for each type:

| Type | Before | After |
|---|---|---|
| **Bug** | Right before the step that goes wrong | The problem on screen. If it used to work and both versions can be opened, Before can be the old version working and After the current one failing. |
| **Feature** | How it looks today | A mock-up or an example from elsewhere, if the user has one. Otherwise just the "today" screenshot. |
| **Task** | The current state | Usually not needed |

### 3a. A web page you can open: capture it yourself

If the problem is on a website or web app you can reach (live site, staging, or a local dev server like `http://localhost:3000`), capture the evidence yourself with the bundled Playwright template. It drives a real browser through the same steps as the issue.

1. **Set up once**: `bash "<this skill's folder>/scripts/setup_capture.sh"`. It needs Node.js and prints `CAPTURE_DIR=...`, the folder to run captures from. The scripts only find their tools from inside it.
2. **Write the steps**: copy `scripts/capture_template.mjs` to `$CAPTURE_DIR/capture.mjs` and edit only its FLOW section:
   - Use one `step('Step N: …', action, { target })` per line of *Steps to Reproduce*, with the same wording, so the GIF and the issue match. Captions are plain text, so use quotes rather than `**bold**`.
   - Call `snap('before')` right before the step that goes wrong, and `snap('after')` once the problem shows.
   - Record what the screen actually says with `fact('Message shown', …)`. The facts let a reader check the pictures, and they go under the images in the issue.
   - Wait on real things (`settle: () => page.getByText('Saved').waitFor()`) rather than fixed delays.
3. **Run it** with a new, empty output folder:
   `cd "$CAPTURE_DIR" && BASE_URL="<url>" OUT_DIR="<empty folder>" node capture.mjs`
   You get `before.png`, `after.png`, `steps.gif`, `recording.webm` and `facts.txt`. If the site needs a login, ask the user to set `EVIDENCE_USER` and `EVIDENCE_PASSWORD` (ideally a test account). Never write passwords into the script or the issue.
4. **Look at the pictures before uploading.** Open `before.png`, `after.png` and a few GIF frames. If *after* doesn't clearly show the problem, the steps aren't right yet, so fix the flow and run it again. A picture that doesn't show the problem proves nothing. If the problem doesn't happen at all, tell the user. It may already be fixed, or need steps you don't know yet.

The capture really clicks and types. On a live site, don't run steps that buy something, delete things, send emails or change real customers' data. Use a staging site or test account, or ask the user first, and undo test changes afterwards if you can.

### 3b. Something you can't open: ask the user

For desktop or phone apps, sites behind a login you don't have, or a customer's own site, ask the user for the same Before / After pair and a recording. Tell them how in plain words:

- **Windows**: press **Windows + Shift + S** for a screenshot. To record, open **Snipping Tool** and choose the video option (newer Windows 11 versions: **Windows + Shift + R**).
- **Mac**: press **Cmd + Shift + 4** for a screenshot, or **Cmd + Shift + 5** to record the screen.
- **Phone**: the normal screenshot buttons, or Screen Recording from the quick-settings panel.

Ask them to save the files and tell you where they are. If they pasted an image into the chat, explain that you need the saved file's location (for example `C:\Users\me\Desktop\error.png`) to upload it. If they have no evidence, carry on without it.

### 3c. Upload to the user's own gist

```bash
bash "<this skill's folder>/scripts/upload_evidence.sh" -t "<issue title>" "<file1>" "<file2>" ...
```

The script creates a **secret** gist in the user's GitHub account and pushes the files to it with git (the gist API only accepts text files). It prints one line of Markdown per file under `---MARKDOWN---`:

- Images and GIFs come back as `![...](...)` and display inside the issue. GIFs play automatically.
- Videos (`.webm`, `.mp4`, `.mov`) come back as a "🎥 Watch video" link. GitHub only plays videos that are dragged into its own editor, so a link is the best a gist can do, and some browsers download the file instead of playing it. That's why the GIF matters: it's the thing people will actually watch.
- If the token is missing the gist permission, ask the user to run `gh auth refresh -s gist`. If gh isn't logged in, ask them to run `gh auth login`.

**Privacy check before uploading.** "Secret" gists are unlisted, not private: anyone who has the link can open them. Tell the user this in plain words before uploading, especially if the repository is private or the screenshots might show personal data, passwords, customer details or internal information. Upload only once they're comfortable, or let them crop or blur the files first.

### 3d. Lay out the Evidence section

Put the pair side by side in a table, with headings that say what each picture shows, then the GIF, the video link and the facts. Leave out any part you don't have.

```markdown
## Evidence
| Before: <what the screen shows, e.g. switch is **On**> | After: <the problem, e.g. switch **Off** but the pop-up still appears> |
|---|---|
| ![before](<url>) | ![after](<url>) |

**Step by step** (plays automatically):

![steps](<url>)

🎥 [Watch the full recording](<url>)

**What the screen showed:**
- <fact, in plain words>
- <fact>
```

## 4. Show a preview and file it

Filing creates something public on GitHub, so show the user the full title and body first and ask if they'd like to change anything. Once they say it's good:

```bash
gh issue create --repo <owner/repo> --title "<title>" --body-file <path-to-body.md>
```

Write the body to a temporary file and use `--body-file`. Passing it inline breaks easily on quotes and newlines, especially on Windows.

Also record the type in GitHub itself, so the issue can be filtered by it. Use only what already exists in the repo, and never create new types or labels:

- **Issue type** (`--type`): GitHub's built-in issue types are Bug, Feature and Task, the same three this skill uses, but only repositories owned by an organization have them. If the owner is an organization, check with `gh api orgs/<owner>/issue-types --jq '.[].name'` and pass the matching name, e.g. `--type Bug`. If the org renamed them, use the closest one. For personal repos, or if the call fails, skip this. The Type section in the body still shows it.
- **Label** (`--label`): check `gh label list --repo <owner/repo>` and add the closest existing label: Bug → `bug`, Feature → `enhancement` or `feature`, Task → `task` (or `documentation` if the task is about docs). If nothing fits, add no label.

If `gh issue create` fails because of `--type` (older gh versions don't have it), retry without it and tell the user the type is shown in the body only.

Finish by giving the user the issue link and the gist link, in one or two plain sentences.

## Example

User: "the save button on the profile page doesn't work, here's a screenshot C:\Users\sam\Desktop\save.png, repo is acme/website"

Title: `Profile changes are not saved after clicking "Save"`

```markdown
## Type
Bug

## Description
When you change your details on the Profile page and click **Save**, nothing is saved. Your old details come back after the page reloads, so people can't update their information.

## Pre-condition
- You are logged in to the website.

## Steps to Reproduce
1. Go to the website and log in.
2. Click your name in the top-right corner, then click **Profile**.
3. Change your **Phone number** to any new number.
4. Click **Save**.
5. Reload the page.

## Actual Result
The page shows the old phone number. No message appears to say whether saving worked.

## Expected Result
The new phone number is kept after reloading, and a message such as "Profile saved" appears.

## Evidence
| Before: new number typed in, about to click **Save** | After: page reloaded, old number is back |
|---|---|
| ![before](https://gist.githubusercontent.com/sam/abc123/raw/def456/01-before.png) | ![after](https://gist.githubusercontent.com/sam/abc123/raw/def456/02-after.png) |

**Step by step** (plays automatically):

![steps](https://gist.githubusercontent.com/sam/abc123/raw/def456/03-steps.gif)

🎥 [Watch the full recording](https://gist.githubusercontent.com/sam/abc123/raw/def456/04-recording.webm)

**What the screen showed:**
- Phone number before saving: 555-0199
- Phone number after reloading: 555-0100
- No "saved" or error message appeared
```
