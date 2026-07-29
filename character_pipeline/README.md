# Dreadbound 3D-to-2D character pipeline

This pipeline replaces separately generated front/back/left/right body parts with
frames rendered from one rigged 3D character. Every direction therefore shares
the same anatomy, clothing, weapon scale, joint placement, camera and lighting.
The game remains 2D; Blender is an offline asset-production tool only.

## Approved free source

Use the free Quaternius **Universal Base Characters** GLB/FBX pack and the
standard **Universal Animation Library**:

- Base characters: https://quaternius.com/packs/universalbasecharacters.html
- Animations: https://quaternius.itch.io/universal-animation-library

Both are CC0 and permit commercial use. Keep the downloaded archives outside the
repository. Only commit the rendered PNG atlases, `manifest.json`, and a copy of
the source/version/license record. Do not use an unknown mirror.

The free base pack is sufficient; the paid `.blend` source kit is not required.
The free standard animation archive includes locomotion and combat data. Confirm
the action names in Blender and update `dreadbound.json` if the downloaded pack
uses different names.

The Standard base-character archive currently contains two glTF texture-name
typos (`*_Normal_png.png` references for files stored as `*_Normal.png`). The
renderer corrects those URIs in a temporary sibling glTF during import and does
not modify the downloaded source.

## First render

1. Install Blender 4.x.
2. Download the CC0 base character and animation packs from the links above.
3. Use the Godot/Unreal glTF character and the non-root-motion Godot GLB
   animation library. The pipeline verifies their shared Quaternius humanoid
   bone contract and applies the imported actions to the character armature.
4. Run:

   ```bash
   blender --background --python character_pipeline/render_directional_sprites.py -- \
     --character "/absolute/path/to/Superhero_Male_FullBody.gltf" \
     --animations "/absolute/path/to/UAL1_Standard.glb" \
     --output assets/art/characters/rendered3d/base_drifter \
     --preset character_pipeline/dreadbound.json
   python3 character_pipeline/validate_output.py \
     assets/art/characters/rendered3d/base_drifter
   ```

Do not pass `UAL1_Standard_RM.glb`: Godot owns player translation, so baking
root motion into the sprite frames would produce visible foot drift.

The output contains one horizontal transparent atlas for each
animation/direction pair plus a manifest. A 128×128 source frame is intentional:
Godot may display it at 64×64 while retaining cleaner silhouettes and enough
horizontal space for side-view melee and death poses.
The preset defaults to low-sample Cycles CPU rendering so the pipeline also
works in headless build workers without EGL or a physical GPU.

## Standard melee weapon-layer test

`render_standard_melee_weapon.py` opens the checked-in
`dreadbound_weapon_actions.blend`, builds a standard sword on `hand_r`, and
renders synchronized `Sword_Idle` and `Sword_Attack` RGBA layers. The embedded
mannequin is a render holdout: it writes no body pixels but removes sword pixels
that pass behind the body. Camera calibration maps the mannequin joints to the
published `base_drifter` atlases.

```bash
blender --background character_pipeline/dreadbound_weapon_actions.blend \
  --python character_pipeline/render_standard_melee_weapon.py -- \
  --output assets/art/weapons/character_layers/standard_melee_sword \
  --preview-output /tmp/dreadbound-sword-preview
```

The runtime copies the body sprite's animation, frame, and frame progress to
the weapon layer every update. It never runs a second independent animation
clock.

## Direction and camera contract

- One model, armature, material set and animation take is used for all views.
- Direction is created only by rotating the top-level character roots around Z.
- The camera and lights never move between directions or frames.
- `front_yaw_degrees` is the only accepted orientation correction. Do not edit
  individual frames or direction-specific bones.
- All atlases must pass `validate_output.py` before Godot import.

If the first preview faces the wrong way, adjust `front_yaw_degrees` once. Never
repair left/right by mirroring or by generating a second character.

## Clothing, professions and equipment

Start with one naked/base character and one animation set. Profession clothing,
hair, shoes, armor and weapons must be rigged to the same armature.

For production, render aligned layers from the same scene:

1. body;
2. hair/head;
3. profession outfit;
4. shoes;
5. weapon/shield;
6. optional effect mask.

Each layer uses identical frame count, camera and direction rotation. This keeps
runtime recoloring and equipment swaps possible without recreating anatomy.
Do not create a different skeleton per profession.

## Humanoid action timing contract

`UAL1_Standard.glb` is the timing authority for every reusable humanoid action.
The pose exporter must preserve the exact baked keyframe positions from the
downloaded GLB. Never round Blender's imported subframes or resample every
action to one fixed pose count: the source is a 30 FPS library whose actions
have different lengths.

The five new Dreadbound actions are limited to the equipment that needs new
motion today: bow idle/draw/release and shield idle/block. Two-hand firearm,
heavy-weapon and shield-impact actions are not padded into the library before
their gameplay exists. The four staff actions keep their downloaded UAL timing
and body motion, then pass through Blender IK calibration against the standard
staff grip.

Every authored action names both a `pose_action` and `timing_action` in
`humanoid_action_library.json`. The pose action supplies a stable full-body
base while Blender IK authors the weapon contacts. The timing action alone
supplies FPS, frame count and duration. An authored action may change its poses,
but must not invent a separate runtime cadence.

Regenerate the runtime tracks with:

```bash
blender --background --python character_pipeline/export_ual_humanoid_poses.py -- \
  --animations "/absolute/path/to/UAL1_Standard.glb" \
  --config character_pipeline/humanoid_action_library.json \
  --output content/humanoid_action_tracks.json
blender --background --python character_pipeline/author_weapon_actions_blender.py -- \
  --animations "/absolute/path/to/UAL1_Standard.glb" \
  --config character_pipeline/humanoid_action_library.json \
  --tracks content/humanoid_action_tracks.json \
  --blend-output character_pipeline/dreadbound_weapon_actions.blend
```

`tests/test_humanoid_action_library.gd` locks the source frame counts and every
authored timing-template mapping. The `.blend` file contains the original UAL
armature, dimensioned bow/staff/shield references, named contact markers and
the five new actions and four staff calibrations. Run the test whenever the source GLB, exporter,
Blender-authored actions or runtime playback changes.

## Migration rule

The rendered atlas is the production character presentation. The retired
`Skeleton2D`/`Bone2D` runtime is not shipped as a fallback. Any future
profession, outfit, or equipment variant must use the same offline-rendered
frame contract instead of reintroducing runtime bones.

The first acceptance target is visual, not merely file existence:

- feet remain on the same ground line in every direction;
- left/right limbs cannot swap identity;
- weapon grip stays in the same hand through a full animation;
- the silhouette remains readable at 48×64 display size;
- walk contact frames do not slide;
- front/back body proportions match exactly.

Direction names always mean the direction the character faces in gameplay.
The source turnaround is ordered `front, right, left, back`; it is not ordered
by the camera side being photographed. Blender projection uses 270 degrees for
logical left and 90 degrees for logical right. Do not swap anatomical
left/right bone names while mirroring a side skin.

The action-preview weapons are neutral code-drawn references. They must never
load `equipment_runtime.png`, `basic_weapons.png`, inventory icons, or any
other production equipment art. Bow references attach to the anatomical left
hand, sword/pistol/staff references to the right hand, and shields to the left.
