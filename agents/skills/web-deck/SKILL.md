---
name: web-deck
description: Build a presentation as a bespoke single-file web app — a continuous scrollytelling canvas stepped through with the keyboard, markdown content layer, full-bleed layouts, pluggable design tokens, print-to-PDF static output — instead of PowerPoint/Slidev/Reveal. Use when the user wants a slide deck, pitch deck, ELT/exec presentation, RFP deck, or asks to turn content into slides with a polished web-native look and a PDF deliverable.
argument-hint: [topic or content source]
---

# Web Deck — Stepped Scrollytelling Presentation Engine

Build presentations as a single continuous scroll canvas that the presenter *steps* through, rather than slideware with discrete slide swaps. The premise: AI is far better at producing polished, on-brand layouts in HTML/CSS (especially against a design system) than in PowerPoint, and a web deck can still compile to a pixel-perfect PDF. Presentation frameworks (Slidev, Reveal.js) cap visual richness at "tech conference template" — a bespoke page does not.

**A complete working example ships with this skill at `example/index.html` (same directory as this file). Read it before building a deck — it is the canonical implementation of the content parser, waypoint engine, segmented spine, scrubbed sections, and static/print fallback, and it doubles as a feature tour you can open in a browser.**

## The interaction model

One long scrollable document of full-viewport sections. **Scroll position is the single source of truth** for all animation state — there is no separate slide index driving the visuals.

- **Stepped navigation:** `Space`/`ArrowDown` smooth-scrolls to the next waypoint; `ArrowUp` to the previous; `Home`/`End` jump. The presenter clicks through it like a deck.
- **Free scrolling still works:** trackpad/wheel scrolling produces exactly the same visuals, because everything is scroll-driven. Keyboard steps are just programmatic scrolls to known offsets.
- **Scroll snapping:** free scrolling settles on the same stops the keyboard uses — `scroll-snap-type: y mandatory` on the root, `scroll-snap-align: start` on sections. The scrub wrapper itself must be `scroll-snap-align: none` (snapping it to `start` would make mid-scrub positions unrestable); instead give it invisible 1px absolutely-positioned snap markers at the waypoint offsets (`top: calc((100% - 100vh) * (i + 0.5) / n)`), so wheel scrolling rests cleanly on each stage. The **last** stage's marker/waypoint sits at 100% of the travel, not its center — otherwise the section's progress fill parks short of full while resting on the final stage. Disable snapping in static mode.
- **Waypoints** are the ordered list of stop points: every section start, plus intermediate keyframes inside scrubbed sections. Derive them from the content data; recompute on resize.
- **Two section kinds:**
  - **Reveal sections** — content animates in as the frame enters (IntersectionObserver adds a class past ~25% visibility) and **replays on every visit**: the class is removed once the element is fully off-screen, so the reset is never visible and stepping back to a section re-runs its entrance like a real deck.
  - **Scrubbed sections** — the signature scrollytelling move: a tall wrapper (height scaled to stage count) with a `position: sticky` inner stage pinned to the viewport; scroll progress through the wrapper (0→1) scrubs a multi-stage animation (a pipeline advancing, a graph building, elements morphing). Each stage boundary is a keyboard waypoint, so `Space` steps *through* the animation, not past it. Scrubs are reversible.

**Sticky-pin gotchas** (both produce the same symptom — a long blank stretch instead of a pinned stage):
- Never put `overflow: hidden` on the wrapper or its ancestors — it creates a scroll container, which silently disables `position: sticky`. Use `overflow: clip` to contain decorative elements.
- Don't let `align-content: center` reach the wrapper (e.g. from a shared section rule) — it applies to block containers too (Chrome 123+) and rests the sticky stage in the *middle* of the tall wrapper. Set `align-content: start` on the wrapper; center inside the stage instead.
- Verify the pin empirically: probe `stage.getBoundingClientRect().top === 0` at several scroll fractions across the travel (e.g. 0.05–0.95), not just one point.

## Core pillars (non-negotiable)

### 1. Content is a markdown document
All copy lives in one markdown block (`<script type="text/x-deck">`) at the top of the file, parsed at runtime by a small deterministic parser (~40 lines, no library). The DOM is rendered from it — **no copy hardcoded in markup**. The owner edits the deck like a document.

The content grammar (as implemented in the example):
- `---` on its own line separates sections.
- Leading `@key: value` lines set section config — `@type:` picks the renderer, `@eyebrow:` the kicker label. New needs = new directives.
- **Heading levels govern typography**, mapped to a fixed type scale: `#` deck title (`.t1`), `##` section title (`.t2`), `###` item heading (`.t3`). Renderers never invent font sizes.
- Paragraphs before the first `###` are the section lede; `- ` lines become styled lists.
- Each `###` heading + following paragraph is an *item* — a grid card, a scrub stage, or a big-number cell, depending on the section type. `- ` lines inside an item render as a bulleted list in its card.
- Inline subset: `**bold**`, `*em*`, `` `code` ``. HTML-escape first, then substitute.
- Deck-level directives live on the hero section: `@brand:` / `@logo:` feed the slide footer; the hero title doubles as the presentation title; `@pager: top|bottom` opts into a horizontal page stepper (chapter name + one dot per slide of the current chapter, click to jump) — off by default, the spine is the primary nav.
- `@appendix: yes` marks backup slides (placed after the closing section): keyboard flow and `End` skip them, but they stay on the spine (dimmed, gapped), reachable by deep link and free scroll, and they print with the deck.
- `@chapter:` on a divider names the chapter it opens for the spine's grouped navigation (falls back to the divider's title).
- Renderer-specific directives extend the grammar without touching the parser: `@cols:` (force grid columns — 1×3, 2×2, 2×4), `@image:`/`@side:` (text + image), `@align:` (divider centring), `@units:`/`@labels:` (timeline resolution and axis), `@role:`/`@photo:` (profile), `@featured:` (pricing tier highlight).
- People photos: a `![name](url)` line in a team item (or `@photo:` on a profile) renders a real photo avatar; without one, a deterministic initials SVG is generated. Unsplash CDN URLs (`images.unsplash.com/photo-…?fit=crop&crop=faces`) work as placeholders — note external images need network, a deliberate exception to the self-contained pillar.

Test of success: the owner can fix a typo or reword a bullet by editing one obvious line of markdown, without understanding the layout code.

### 2. Pluggable design tokens
- Every visual variable (colors, type scale, spacing, radii, gradients, shadows, easing) comes from a single `:root` custom-properties block (or the Tailwind config if Tailwind is in play). No magic hex values in layout code. Swap the block, rebrand the deck.
- If the user has a design system or brand guide, ask for it (tokens file, Tailwind config, or even a screenshot) and map it into the token block. The deck should look like their product, not like a template.
- **No design system? Ask, don't guess.** Use AskUserQuestion to offer 3–4 distinct aesthetic directions and build the token block from the answer, e.g.:
  - **Midnight** — near-black blue-tinted stage, one electric accent, glow blobs, gradient numerals (the example's theme)
  - **Editorial** — warm paper background, serif display headings, ink text, one restrained accent
  - **Terminal** — pure black, monospace throughout, single phosphor accent, hard 1px borders
  - **Bold** — saturated color-block sections, oversized type, high contrast, minimal chrome
  Whatever they pick, commit fully — never ship a gray default with animations bolted on.

### 3. Full-bleed, presentation-scale layout
- This is a presentation, not a web page: sections fill the whole screen (`min-height: 100vh`, full width). **No global max-width column** — compose edge-to-edge with grid, using generous token-driven padding.
- **Slide anatomy**: eyebrow + title sit at the top of the frame — wrap them in a `<header>` and lay sections out as `grid-template-rows: auto 1fr`. **Body content never starts above the heading's bottom** — layouts with side columns (text + image, profile) put only the identity/heading in the header and everything else below it. Body content centers in the remaining space (media images vertically center against their copy), except grids, which stretch to use the available height (`align-self: stretch; grid-auto-rows: 1fr`) so longer card content gets room instead of clipping. Statement slides (hero, closing) stay vertically centered via an explicit `center` class.
- **Every slide carries a footer**: brand logo/name (left), presentation title (center), page number `NN / TT` (right) — read from deck-level directives on the hero (`@brand:`, `@logo:`). Render it per-section, absolutely positioned in the bottom padding (inside the sticky stage for scrubs) — **not** `position: fixed`, which repeats in print but freezes the page number on every page.
- Constrain line length locally where a text block needs it for legibility (`max-width: 58ch` on that element), never by boxing the whole canvas.
- Type at presentation scale: `clamp()`-sized headlines and key numbers legible from the back of the room, not sized for a browser tab.

### 4. Native-first, library-agnostic motion
The animation richness is the point — staggered entrances, scrubbed sequences, layered gradients and glows — but don't hard-couple the output to any one library; the space shifts.
- **First reach:** native primitives. `position: sticky` for pinning; IntersectionObserver for reveals; a rAF-throttled scroll listener mapping wrapper progress to stage index; CSS transitions with per-element `--d` delay variables for staggering; CSS scroll-driven animations (`animation-timeline`) where support suffices.
- **Escalate only when needed:** if the deck genuinely needs orchestrated timelines, spring physics, or scrub-linked morphing beyond native comfort, pull in one current, well-maintained library (at time of writing: GSAP ScrollTrigger, or Motion) via CDN. Name the tradeoff to the user before adding it.
- Motion tasteful-by-default: fast (200–600ms), custom eased, purposeful.

### 5. Static mode: reduced-motion and print are the same layout
- Build a **static mode** (`html.static` class) from the first draft: reveals fully visible, scrub wrappers collapsed to natural height with the stage unpinned, every scrub rendered at its *completed* state alongside a plain readable list of its stages.
- Trigger it from `prefers-reduced-motion` at init and from `beforeprint`.
- The `@media print` block adds the paging: one section per page (`break-after: page`), `print-color-adjust: exact` so backgrounds/gradients survive, `@page` sized to the deck's aspect, spine and hint chrome hidden.
- Deliverable check: Cmd+P in Chrome → each section is one crisp vector page. A deck that presents beautifully but prints blank/clipped is not done.

### 6. Single self-contained file
- One `index.html`: content block, tokens, styles, renderers, engine. Zero dependencies by default; CDN links only when motion needs escalate (pillar 4).
- No build step, no node_modules. Open the file, present.

## The segmented spine

A fixed rail on the left edge, one segment per section:
- Segment length is proportional to the section's scroll height (scrubs read longer, honestly).
- **Chapters:** a `divider` slide opens a chapter (named by `@chapter:`, falling back to its title); end and appendix slides stand alone; everything before the first divider is auto-labelled "Intro". The rail is a section stepper with the page stepper nested inline: the current chapter expands into its per-slide segments at full weighted size, while every other chapter renders as **one** summary segment with an aggregate fill — never a squash of hairline slivers. Clicking a summary jumps to the chapter's first slide.
- Each segment fills with that section's own scroll progress — together they read as both "where am I" and "how much is left".
- **Segments are buttons**: click one to jump to its section; the active segment tints accent.
- **One TOC panel, not per-segment chips**: hovering the rail opens a single flyout panel — chapter names as clickable headings, numbered slide rows beneath, active row highlighted, appendix rows dimmed below a separator, scrollable past ~84vh. Per-segment floating chips do not survive a 30-slide deck (ragged widths, overlapping stacks, chips covering the slide content); one aligned surface does. Keep the panel a child of the rail so hovering it keeps the rail's `:hover` alive — but scope segment styles to the group container (`.sgroup button`), never `.spine button`, or the panel's own buttons inherit segment widths/backgrounds and the rows collapse on hover. Give the rail a padding halo so the thin resting state is easy to catch. Blur buttons after a click — otherwise `:focus-within` (kept for keyboard users) holds the panel open.
- Hidden in print; `aria-label` per segment for accessibility.

## Nice touches (include unless the user objects)

- **URL hash sync:** `history.replaceState` the current section's id while scrolling, so refresh/share lands in the right place; honor an incoming hash on load.
- **Presenter hint:** a pulsing "space / ↓ to begin" line on the hero, hidden in print.
- **Count-up numerals:** big numbers animate from zero on reveal.
- **Overview mode (`O`):** the canvas becomes a clickable grid of every slide; click one to jump, `O`/`Esc` returns. Enter it together with static mode so scrubs/reveals flatten, and scale tiles with `zoom` — not `transform`, which doesn't shrink layout boxes and leaves huge grid gaps.
- **Speaker notes + presenter window (`N`):** `Note:` lines anywhere in a section are speaker notes — collected by the parser, never rendered on the slide. `N` opens a presenter popup (current slide, notes, next slide, elapsed timer) styled from the deck's own tokens. Drive its DOM directly via the `window.open` handle — `about:blank` inherits the opener's origin; don't reach for BroadcastChannel, which is unreliable on `file://`.
- **Annotate mode (`A`):** a full-viewport `<canvas>` overlay for drawing on the deck — native pointer events, no library. Strokes anchor to *document* coordinates and persist per deck in localStorage, so scrolling stays live while inking (mark up the whole deck in one pass, survives refresh); redraw the canvas on scroll with the stored strokes offset by `scrollY`. `C` clears the current slide's strokes, `A`/`Esc` exits. Ink in `--accent-2` so it reads as markup, not design. A corner badge stamps the current section id, so an OS screenshot (macOS `Cmd+Ctrl+Shift+4` → clipboard) pasted into a review chat self-identifies which slide/markdown block to edit. Hidden in print. Gotcha: size the bitmap at `devicePixelRatio ×` viewport for crisp strokes **and** give the canvas CSS `width/height: 100%` — with `width: auto` a canvas displays at its intrinsic bitmap size, so on retina every stroke lands at 2× the cursor.
- **Comment mode (inside annotate):** double-click drops a numbered pin and a typed note at that spot (click a pin to delete); notes persist in localStorage keyed by section id and fractional position. `E` copies every note to the clipboard as a markdown punch list — `- [#six-pillars] tighten this heading` — so pasting it into a review chat tells the agent exactly which markdown block each item targets.

## Workflow

1. **Intake first.** If the invocation didn't include a topic or content source, ask for it. Then ask a few shaping questions (AskUserQuestion, batched, skip any already answered): audience & occasion (exec review, sales pitch, RFP, conference, internal), the single takeaway the deck must land, roughly how many minutes/slides, and what source material exists (doc, outline, data, nothing yet).
2. **Narrative second.** Shape the answers into a section-by-section outline: title + one-line message per section, and a layout type from the library for each. Mark which sections deserve a scrubbed sequence (a process, a build-up, a before/after) vs. a simple reveal. Where content fits no existing type, propose a new type (name + one-line layout sketch) rather than forcing it into the wrong one. Present the outline for confirmation before writing any code.
3. **Tokens third.** Ask about design system / brand; if none, run the aesthetic-direction question (pillar 2) and build the token block from the answer. Two optional intake questions alongside:
   - **Style-match a site?** Offer to take URL(s) — the user's product, marketing site, or an existing deck — and extract palette, type feel, and radius from them into the token block, rather than describing the aesthetic from scratch.
   - **Client co-branding?** For proposals/RFPs, ask for the prospective client's site or logo. Default treatment: the deck stays in the *user's* template; client branding enters as their logo placed beside the user's in a footer strip on every content slide (skip statement slides if it fights the composition, keep it in print). Render the client logo monochrome/white-out if its palette clashes with the theme. Only pull client colors into the deck itself when explicitly asked — restraint reads as confidence.
4. **Build.** Start from `example/index.html` as the reference implementation: markdown block → renderers per section `type` → waypoint/scroll engine → spine → static mode + print CSS. The example ships a layout library covering the common deck needs — `hero`, `agenda` (auto-generated from chapter dividers, hash-linked), `prose`, `divider` (section separator — large vertically centred heading; `@align: center` centres it horizontally too), `grid` (auto or `@cols`-forced), `scrub`, `numbers`, `media` (text + image), `diagram` (linear flow of nodes), `cycle` (items on a ring, read clockwise — the whiteboard loop), `relations` (entities on a ring with directed labelled edges from `-> Target | label` body lines; deterministic ring layout reads fine to ~7 entities), `timeline` (gantt-like bars), `chart` (single-series bars from one number per item; `@max`/`@unit`), `quadrant` (2×2 positioning chart, items plot from an `x,y` line on a 0–10 scale; `@x`/`@y`/`@labels`), `funnel` (narrowing stages from `value | label` lines), `compare` (two panels + vs seam; `@winner` highlights a side), `quote` (pull-quote — the title is the quote; `@cite`/`@role`/`@photo`), `logos` (social-proof wall; image or wordmark fallback), `team` (people cards with generated initials avatars), `profile` (one-pager), `pricing` (commercial tiers), `mirror`, `end`. Reuse these; a new layout need = a new type, not a one-off hack.
   Print-context gotchas the example already encodes: media queries in print evaluate against the printer's default page size, not the `@page` px size — scope responsive stacking to `@media screen`. The interactive print preview resolves `vw`/`vh` against the printer's paper too, shrinking every viewport-sized value — so viewport units are tokens (`--vw: 1vw` etc., used as `calc(5 * var(--vw))`, never raw) and `@media print` pins them to the `@page` size ÷ 100. The page background must be painted on each `section` in print — the interactive print dialog never paints the root/body canvas background (that's the "Background graphics" checkbox, which `print-color-adjust` cannot override), but it does honor `exact` on element backgrounds; keep `exact` on `body` too since it's inherited by everything else. Gradient text via `background-clip: text` prints with box artifacts — go solid in static mode.
5. **Verify.** Run `verify.sh <deck.html> [raster-dir]` (ships with this skill, same directory) after every build — it smoke-tests the renderers/engine via headless Chromium `--dump-dom`, curl-checks external image URLs, drives the real print pipeline via `--print-to-pdf`, and asserts **page count == section count** (a split page means an overflowing section). Pass a raster dir to also get `pdftoppm` PNGs of every page — Read/eyeball them; this loop caught every print bug in the example. Then have the user (or a browser session) step the deck end-to-end with the keyboard, free-scroll it, click spine segments, and check print preview — all of it must work before the deck is "done".
6. **Iterate on content in the markdown.** Wording changes → edit the content block only. Look-and-feel changes → tokens/renderers only. If a request forces you to break that boundary, flag it.

## Anti-patterns

- Copy embedded in markup or render functions — everything readable belongs in the markdown block.
- Renderers choosing their own font sizes — heading level → type scale is the only path.
- A max-width centered column wrapping the whole canvas — that's a web page, not a presentation.
- Two sources of truth for position (a slide index *and* scroll state) drifting apart — scroll position drives everything; the keyboard is just a scroller.
- Reaching for a heavy animation bundle before native primitives have been tried.
- A deck that looks great live but prints as a single blank/clipped page — static mode is a first-class requirement, not a follow-up.
- Framework lock-in (converting the ask into a Slidev/Reveal/React project). The output is a bespoke file the user owns entirely.
- Unthemed defaults: if no design system exists, ask for a direction and commit to it — never browser-default styling with animations bolted on.
