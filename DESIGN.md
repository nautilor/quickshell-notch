# Design

The UI choices behind this config, and the reasons for them. Token values live in `config/Theme.qml`; icon mapping in `config/Glyphs.qml`. Screenshots are in `docs/screenshots/`.

## Concept

One surface, many states. Everything lives in a single black shape hanging from the top edge of the screen, in the spirit of Boring Notch and the Dynamic Island. The shape changes size and content instead of spawning separate windows, so the shell feels like one object that breathes rather than a set of popups.

The look is Material 3 Expressive: very rounded shapes, tonal colour, big touch-friendly targets, and motion with a little overshoot. It is used on top of a black base so that the notch merges with the screen edge and wallpaper stays the star.

## The shape

- **Notch silhouette.** Concave "ears" at the top corners flow into the screen edge, and the bottom corners are rounded. The silhouette is one path (`Notch.qml`), recomputed from width, height and two radii, so every size is the same shape and not a scaled picture.
- **Radii follow the state.** Idle uses small radii (top 8, bottom 14), so it reads as a pill. Messages and notifications use medium ones (16 / 26). The open notch uses large ones (24 / 34), which echo the rounded cards inside it.
- **Near-black fill.** The notch colour is a barely tinted black (`tone(0.12, 0.035)`), not pure black. It stays dark enough to merge with a hardware notch or a dark bezel, while still belonging to the palette.
- **Click-through window.** The layer-shell window is larger than any state (960 × 620) and uses an input mask, so the empty area never blocks clicks. The mask is the shape plus a few forgiving pixels.
- **Rounded screen corners.** An optional overlay rounds all four corners of every screen in the notch colour, so the screen and the notch share one visual language.

## States

| State | Size | Content |
| --- | --- | --- |
| Idle | content-sized, 34 high | workspace chip, album art, optional date / clock, status icons, battery |
| Message | about 250–320 wide, 56 high | round icon + text, and a slider for volume and brightness |
| Notification | 440 wide, 60 or 108 high | icon, text, two dismiss buttons, optional action buttons |
| Open | per tab, from 600 × 260 to 920 × 580 | tab bar + tab content |

- **Sizes are per tab.** Each tab gets the room it needs (Power is small, Calendar is large) instead of one fixed panel, so small tabs do not feel empty.
- **Content cross-fades, the shape springs.** The shape resizes with a spring while the old content fades out and the new one fades in. This hides layout jumps and keeps the motion readable.
- **Idle width adapts.** Both sides of the idle notch take the width of the wider one, so the centre text always sits in the middle with a clear gap and the icons never touch it.
- **Priority.** Open beats notification, which beats message, which beats idle. Only one thing is shown at a time.

## Colour

- **One seed hue.** The whole palette is derived from a single hue (`Settings.hue`) with fixed saturation and lightness per role. Changing the accent in Settings recolours everything consistently.
- **Roles, not colours.** Components ask for roles (`primary`, `primaryContainer`, `surfaceContainerHigh`, `tertiary`, and so on), never raw values. Foreground roles end in `Fg`, because a property name starting with `on` is read by QML as a signal handler.
- **Surface ladder.** Four container levels (`Low`, normal, `High`, `Highest`) separate cards from the notch without borders or shadows. Depth is shown by lightness only.
- **Semantic accents.**
  - `primary`: selected and active things (active tab, toggled-on buttons, progress, now-playing).
  - `tertiary`: calendar and "ambient" state (next-event card, caffeine).
  - `error`: destructive or alarming (power off, delete, muted mic, low battery, critical notification).
  - Battery uses its own scale: green while charging, `primary` when full, `error` when low, neutral otherwise.
- **Dark only.** There is no light theme. A black notch on a light wallpaper still looks intentional, and a second theme would double the testing.

## Typography and icons

- **JetBrainsMono Nerd Font Propo** for all text. The proportional variant keeps letter spacing natural while keeping the monospaced character the user already has on their system.
- **Material Design Icons** from the same font, so there is no second font to install. Components still ask for Material-style names (`home`, `bolt`), and `Glyphs.qml` translates them to code points. Swapping an icon is a one-line change.
- **Size scale.** Body 14, secondary 12, captions 10–11, headings 15–19, icons 18–24 (up to 44 for empty states).
- **No filled/outlined switch.** The font has no variable fill axis, so selected state is shown with colour and shape, not by filling the icon.

## Shape language

- **Everything is a pill or a squircle.** Buttons, fields, switches and list rows are fully rounded. Cards use 18–28 px radii (`radiusMedium`, `radiusLarge`).
- **Toggles morph.** A toggle button is a rounded pill at rest and a tighter rounded square when on. Pressing squashes the radius further. This is the main Expressive trait of the design: state is readable from the shape before the colour.
- **Album art morphs too.** The cover is a rounded square while paused and rounder while playing. Corners are clipped with a mask, because a plain `clip` only clips to rectangles.
- **Workspaces.** The active workspace is a wide pill, the others are circles, and occupied ones are tinted. The row shrinks its circles to fit rather than overflowing.
- **Power profile.** One segmented control with a sliding highlight. Only the selected segment shows its label and is wider, so the longest label ("Performance") never touches the edge.

## Motion

- **Springs for size and position.** The notch, tab pills, switches, workspace pills and toggle radii use spring animations with slight overshoot (`springBouncy`: stiffness 3.4, damping 0.30). Softer springs (`springSoft`) are used where bounce would look silly, like the album art corners.
- **Emphasised easing for colour and opacity.** Fades and colour changes use short eased animations (150–300 ms). Springs on opacity or colour look wrong, so they are not used there.
- **Press feedback.** Buttons scale to about 0.96 on press and lose some corner radius. The workspace chip bounces on workspace change.
- **Live feedback.** An equaliser animates while music plays and the sync icon spins while the calendar loads. Nothing else moves on its own, so motion always means something.
- **Restraint.** Nothing animates while the notch is hidden or idle, apart from the clock timer and the equaliser.

## Layout

- **Header + body.** Every open tab shares a header: tab pills on the left, status on the right (caffeine, mic, battery, date and clock, pin). The body is below.
- **Tab bar.** Icons only, except the active tab, which expands to show its label. This keeps eight tabs in a narrow bar and still names where you are.
- **Home** is a two-column dashboard. Left: the media card. Right: workspaces and tray, five equal toggles, the power-profile control, the next event. The player takes the left because it is the most visual element, and the right side is dense but regular.
- **Equal weights.** Toggles share the width equally (`preferredWidth` set to the same value), so labels of different lengths do not make tiles of different sizes.
- **Spacing.** An 8 px base grid: 8 between related items, 10–12 between groups, 12–14 around cards and panels. Right and left margins are the same everywhere, and the tab content has extra room at the bottom to clear the rounded corners.
- **Compact notifications.** The peek uses a 40 px icon, tight text and 28–32 px buttons. It is a glance, not a card, so it stays slim.

## Interaction

- **Hover opens, leaving closes.** Opening takes 140 ms of hover and closing takes 380 ms without it, so brushing past the top edge does nothing and a small slip does not close the panel. The hover handler sits on the window root so buttons and lists inside the notch still count as hover.
- **Open on Home.** Hovering always lands on Home (optional), because the same place every time builds muscle memory. Keybinds go straight to the tab they name.
- **Pin.** The pin button keeps the notch open. Keyboard and IPC opens are sticky, and a click outside or Escape closes them.
- **Keyboard first where typing happens.** Apps and Clipboard focus their search field on open, with arrows to move and Enter to choose. The Power tab has arrow, Tab, Enter, Space and 1–4 shortcuts, with a visible focus ring.
- **Confirm destructive actions.** Log out, reboot and power off need a second press within three seconds. The button turns into a "Tap to confirm" state instead of opening a dialog.
- **Two ways to dismiss a notification.** The eye-off button hides the peek but keeps the notification in the list. The bin removes it completely. A peek does not time out while the pointer is on it.
- **Autohide.** The idle notch slides almost out of view and leaves a 6 px strip, so the top edge is still a hover target.
- **Custom messages.** The caffeine and microphone texts are user-written, because a status message is more useful when it says what the user meant.

## Calendar

- **Same grammar as Google Calendar.** Week columns, an all-day strip, an hourly grid, a red "now" line, and overlapping events laid out in side-by-side lanes. Familiar structure makes a small panel easy to read.
- **Event colour is data.** Events use their Google calendar colour with black or white text chosen by luminance. This is the only place where the palette is not the theme's.
- **Create button.** A floating button at the bottom right, over the grid, like Google Calendar. Clicking an empty slot also creates an event at that hour.
- **Overlay editor.** Editing covers the grid, not a new window, so the notch keeps its size and the user keeps their place.

## Accessibility and limits

- Text colours are chosen from the same tonal family as their backgrounds, with `Fg` roles at about 88–92% lightness on dark surfaces for high contrast.
- Hit targets are at least 32 px, and most are 38–48 px.
- There is no screen-reader support (Quickshell does not expose it), and no light theme.
- Reduced-motion is not handled: springs always play.
