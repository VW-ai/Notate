# Tag Panel Design — "Orbital Palette"

## Concept
The tag panel transforms into a semicircular palette inspired by a solar system: the highest-velocity tags orbit closest to the left focus (the user) and less-used tags drift toward the right horizon. The layout celebrates hierarchy while encouraging playful exploration.

```
             (overlay)                    
          *.  .        .  .*              
        /       ───────       \           
       /   core      glow      \          
      |  #launch prep ●         |         
      |       #deep work ●      |         
      |    #design review ●     |         
      |         #roadmap ●      |         
       \   #quick fix ○       /          
        \     #coffee chat ○ /           
         \    #life admin ○ /            
          \ #misc thoughts ○             
           •───────────────•             
             left focus     right drift  
```

## Geometry & Layout
- **Canvas**: 540×280pt docked to the left edge of the timeline. The straight edge hugs the content; the curved edge faces inward.
- **Orbits**: 5 concentric arcs subdivide the semicircle. Each arc corresponds to a usage tier (Orbit 1 = top 5%, Orbit 5 = bottom 20%).
- **Placement**: Tags within an orbit distribute along the arc using weighted spacing so large chips do not clump together. Highest ranked tags anchor near the left focus and gradually radiate clockwise toward the right terminator.
- **Perspective**: Apply subtle depth by scaling tags slightly (95–105%) based on their angular position to mimic orbital motion.

## Tag Tokens
- **Glyph**: Round pill with a color-core dot (TagColorManager tint) and tag text. Counts appear as soft badges trailing the label (`[#launch prep ● 32]`).
- **Sizing**: Font and pill padding scale per orbit. Orbit 1 uses 18pt semibold, Orbit 5 uses 12pt regular.
- **Glow**: Top two orbits include a faint outer glow matching the tint to sell the “star” concept. Lower orbits use a matte finish.
- **Interaction**:
  - Hover rotates the pill minutely toward the pointer and intensifies glow.
  - Click toggles filter state; selected tags gain a comet tail indicator pointing toward the timeline.

## Tag Detail Card
- **Trigger**: Clicking a tag spawns a floating “orbit card” anchored to the tag’s position. The card slides out from the orbit toward the timeline.
- **Capacity**: Card height supports five info rows without scrolling. If more than five related entries exist, a `View next 5 ⟶` control cycles to the next batch.
- **Row Format**: `🕒 [content snippet…]  |  Tue, Apr 8  |  🌅 Morning  |  #other-tag #second-tag`
  - Content snippet shows the first eight words, truncating with `…` if longer.
  - Time-of-day icons: 🌅 Morning (6a–12p), ☀️ Afternoon (12p–6p), 🌙 Evening (6p–12a), 🌃 Overnight.
  - Other tags render as miniature pills using the same tint system (smaller tier, no comet tails).
- **Ranking**: Rows sort by absolute proximity to “now” (closest upcoming or most recent first). Past items appear above future ones when equally distant.
- **Interaction**: Hovering a row brightens the emoji, clicking opens the entry/event detail pane and closes the card. Pressing `Esc` or clicking outside dismisses the card.

## Search & Controls
- **Search Crescent**: A curved search field sits along the flat left edge, following the arc’s chord. Placeholder `🔍 Filter or create tags…`.
- Typing filters orbits to matching tags; non-matching orbits fade toward transparency but remain in place to maintain spatial awareness.
- **Create Tag**: `+ New tag` button appears as a satellite icon at the lower-left vertex. Clicking spawns an inline composer that orbits into the lowest tier once added.

## Motion Language
- Initial load animates from left focus: tags slide onto their orbit with slight overshoot.
- Filter results cross-fade; tags fly inward/outward along orbital paths rather than snapping.
- Dragging an entry over the panel highlights the closest orbit with a luminous band; potential target tags pulse to invite drop.

## Responsive Behavior
- **Desktop (≥1200px)**: Full semicircle exposed.
- **Medium (900–1199px)**: Panel scales down to 420×220pt; reduce to 4 orbits; search field shrinks but remains along the chord.
- **Small (<900px)**: Panel collapses into a floating “planetary” button. Tapping expands a modal overlay showing the half-circle centered on screen.

## Empty / No Match States
- **Empty**: Show stylized sun core with text “Create a tag to populate your orbit.” Primary action button `Launch first tag`.
- **No Match**: Display a dimmed galaxy with copy `No tags containing “launch” in this quadrant.` Provide quick option `Create “launch” tag`.

## Implementation Notes
- Build a custom `OrbitalLayout` that converts tag rank into polar coordinates (radius = orbit tier, theta = weighted angle).
- Reuse `NotateTag` by adding parameters for `sizeTier`, `glowStrength`, and `rotationAngle` to achieve the orbital look.
- Maintain deterministic placement by seeding a pseudo-random angle offset per tag name to avoid jarring reshuffles between sessions.
- For drag-and-drop, expose the orbit geometry so highlights match the drop zone under the pointer.

## Vertical Rectangle Refresh — Surface & Shape
- **Soft Fold Geometry**: Keep the vertical rectangle but curve the outer-right edge subtly (10–12pt) while the inner edge remains straight, giving the impression of a folded panel that points toward the timeline.
- **Gradient Veil**: Replace the flat `#2C2C2E` with a vertical gradient (e.g., `#1F1F23 → #2C2C31`) that lightens toward the timeline. This creates natural depth without heavy shadows.
- **Glow Spine**: Introduce a 8pt internal spine on the left edge using a low-opacity tint of the top tag; it acts as a chromatic signature and visually anchors the search field.
- **Inset Canvas**: Float the content area inside a 4pt inset with a subtle blur/tint (`materialThin`) so the chip cloud appears to sit on frosted glass. Corners of the inset are tighter (12pt) to contrast with the 20pt outer shell.
- **Shadow Treatment**: Use a dual-drop approach—soft ambient shadow (0,10,30,0.25) plus a thin rim light on the right edge—to lift the panel off the background while keeping the baseline alignment.
- **Panel Footer**: Base hosts a shallow arc cut-out that houses the `+ New tag…` composer, echoing the orbital theme while staying within the rectangular footprint.
