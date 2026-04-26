# Avatar PNG assets

Drop the PNG files for avatar presets in this folder, then activate them.

## Naming convention

`{preset-id}.png` — must match the preset `id` declared in
`lib/shared/widgets/avatar_presets.dart`.

| Preset id | Filename                       |
|-----------|--------------------------------|
| `male`    | `male.png`                     |
| `female`  | `female.png`                   |
| `chubby`  | `chubby.png`                   |
| `snacker` | `snacker.png`                  |
| `strong`  | `strong.png`                   |

`initials` does not need a PNG — it renders the user's letter initials
directly.

## Source spec

- **Format:** PNG with transparent background (alpha channel)
- **Aspect:** 1:1 square
- **Size:** 256×256 minimum (renders at 96 dp on edit-profile, ~28 px in
  picker grid). Larger is fine.
- **Composition:** safe area within the central ~80% — outer 10% may be
  clipped by the circular container.
- **Color:** any. The PNG sits on top of the user-picked color circle, so
  designs should work against any of the 5 background colors (red, green,
  blue, teal, pink).

## Optional retina variants

For crisp rendering on high-DPI displays, add scaled variants:

```
assets/avatars/
  male.png        ← 1.0x (256×256)
  2.0x/male.png   ← 2.0x (512×512)
  3.0x/male.png   ← 3.0x (768×768)
```

Flutter picks the right one automatically based on device pixel ratio.

## Activating an asset

Two changes after dropping the PNG:

### 1. Register the asset folder in `pubspec.yaml`

If not already present, under `flutter:`:

```yaml
flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/avatars/
```

### 2. Set `assetPath` on the preset entry in `lib/shared/widgets/avatar_presets.dart`

Uncomment the `assetPath:` line, e.g.:

```dart
static const male = AvatarPreset(
  id: 'male',
  label: 'Male',
  icon: Icons.man,
  assetPath: 'assets/avatars/male.png',  // ← was commented out
);
```

Run `flutter pub get` and hot-restart. The picker + edit-profile avatar
will render the PNG instead of the Material Icon. If the file is missing
or the path is wrong, `Image.asset` fails gracefully and the Material
Icon shows instead — no crash.

## Going premium / sellable

Add `isPremium: true` and `sku: 'avatar_<id>'` to the preset entry. The
picker will (when the entitlements layer ships) render a lock badge until
the user owns the SKU.

```dart
static const dragon = AvatarPreset(
  id: 'dragon',
  label: 'Dragon',
  icon: Icons.local_fire_department, // fallback
  assetPath: 'assets/avatars/dragon.png',
  isPremium: true,
  sku: 'avatar_dragon',
);
```
