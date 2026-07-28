# Universal Humanoid Skeleton and Skin Specification

All ordinary playable humanoids use one skeleton, one animation set, and one
socket layout. A profession is a skin package, not a new skeleton.

Generated sheets, runtime manifests, previews, and tests must all use the slot
names below. A direction or skin may change textures and draw order, but it
must never rename, merge, or add a joint segment.

## Directions

- `front`
- `back`
- `left`
- `right`

`left` and `right` describe the direction the character faces. Part names
remain anatomical (`left_*` and `right_*`) in all four directions.

## Canonical Frame

Every `humanoid_v1` skin is normalized before it is split:

- frame: `256 × 420`
- body center: `x = 128`
- foot baseline: `y = 410`
- hip line: `y = 230`
- knee line: `y = 322` for near limbs; a far side-view limb may use `y = 324`
- neck pivot: `y = 82`

Front and back use the same crown, hip, knee, and baseline values. Left and
right manifests are exact coordinate mirrors with anatomical side names
swapped. Source illustration bounds never redefine the skeleton.

## Skeleton Slots

| Slot | Contents | Pivot |
| --- | --- | --- |
| `head` | Head, mask, and hood | Neck |
| `torso` | Chest, abdomen, and fixed chest armor | Hips |
| `left_upper_arm` | Left shoulder armor and upper arm | Left shoulder |
| `left_forearm` | Left forearm, glove, and hand | Left elbow |
| `right_upper_arm` | Right shoulder armor and upper arm | Right shoulder |
| `right_forearm` | Right forearm, glove, and hand | Right elbow |
| `left_thigh` | Left thigh and fixed thigh armor | Left hip |
| `left_shin` | Left lower leg, ankle, and boot | Left knee |
| `right_thigh` | Right thigh and fixed thigh armor | Right hip |
| `right_shin` | Right lower leg, ankle, and boot | Right knee |

## Clothing Overlay Slots

| Slot | Contents | Pivot |
| --- | --- | --- |
| `coat_far` | Clothing and belt layer drawn behind the body | Hips |
| `coat_near` | Clothing and belt layer drawn in front of the body | Hips |

The ten skeleton slots are always present. The two clothing overlay slots may
use transparent placeholders when a skin has no hanging garment.

## Skin Packages

### Base undersuit

The common humanoid base is a complete four-direction undersuit skin. It is
not displayed as literal nudity. It provides finished pixels under every
replaceable garment so animation and partial outfit swaps never reveal holes.

The production package is `skins/base_humanoid`. It contains the same 12 slots
as a profession skin and uses transparent 16×16 placeholders for its two coat
slots.

### Profession and outfit skins

A profession or outfit package supplies four-direction textures for any slots
it changes. Unspecified slots fall back to the base undersuit. A complete
profession package normally replaces all ten skeleton slots and may also
provide both clothing overlays.

The base Armorer is the first skin package authored against this standard.
Steadfast, Resonant, Drifter, combat styles, and later outfits reuse the same
skeleton and animations.

## Binding Rules

- Arms have exactly two visible segments: upper arm and forearm.
- Legs have exactly two visible segments: thigh and shin.
- Hands and gloves are painted into the matching forearm sprite.
- Feet and shoes are painted into the matching shin sprite.
- Shoulder armor follows the upper arm when it needs to rotate with that arm.
- Belts, pouches, and coat panels belong to `coat_far` or `coat_near` according
  to their draw order. They do not create extra bones.
- Weapons, shields, charms, ammunition, and tools are never baked into a body
  sprite. Runtime equipment attaches to hand or body sockets.
- Each limb segment includes a painted hidden overlap around its parent joint.
  Rotation within the authored walk range must not expose transparent gaps.
- Neutral sprites are authored on the bone axis. Animation comes from bones,
  not from pre-bent replacement frames.
- Humanoid skins keep the standard joint locations and bone-length ratios.
  Small silhouette changes use per-skin visual offsets; they do not fork the
  animation skeleton.
- A form with a different limb count or a materially non-humanoid structure
  must declare a separate rig family instead of abusing humanoid skin slots.
- Manifests use schema version 3, identify `skeleton_id: humanoid_v1`, and store
  all eight two-dimensional rest vectors. Runtime binding must use vector
  length and angle; reducing a segment to only its vertical distance is invalid.

## Directional Gait

- Left and right views use profile travel, visible stride, and knee lift.
- Front and back views use depth shortening, overlap, and small lateral weight
  transfer. They never reuse the broad profile pendulum.
- Both views solve the two-segment leg toward an authored foot target.
- During the support phase the foot stays on the `y = 410` baseline while hip
  bob is compensated inside the leg target.
- Arm swing remains opposite to its paired leg, but axial arm amplitude is
  deliberately smaller than profile amplitude.

## Equipment Sockets

The shared skeleton exposes stable runtime sockets:

- `main_hand`
- `off_hand`
- `back`
- `waist_left`
- `waist_right`
- `charm`

Equipment changes sockets and IK modes. It never changes the body skin files.

## Skeleton Hierarchy

```text
hips
├── coat_far
├── left_thigh
│   └── left_shin
├── right_thigh
│   └── right_shin
├── torso
│   ├── head
│   ├── left_upper_arm
│   │   └── left_forearm
│   └── right_upper_arm
│       └── right_forearm
└── coat_near
```

## Acceptance Criteria

- The shared skeleton contains exactly ten body slots and two clothing slots.
- Every complete skin contains the same twelve slot keys in all four
  directions; unused clothing slots are explicitly transparent.
- Every part is a separate transparent sprite and can be inspected directly.
- The four manifests use identical part keys and joint meanings.
- A reconstruction preview matches the source skin turnaround in neutral pose.
- Walk previews show two complete cycles in all four directions.
- `left` and `right` are exact mirrored coordinates and visibly face their
  named direction.
- The runtime keeps non-zero horizontal components in side-view rest vectors.
- Front/back knees do not cross the center line during the walk cycle.
- Support feet remain on the shared baseline without whole-body drift.
- Shoulder, elbow, hip, and knee rotations do not reveal holes or hard seams.
- The neutral character is unarmed; equipment appears only through runtime
  sockets.
- At least two different profession skins can be swapped on the same live
  skeleton without rebuilding bones or animation tracks.
