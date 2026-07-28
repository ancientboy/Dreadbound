extends Node2D

# The demo must exercise the production Godot Skeleton2D/Bone2D rig. The
# previous scene added a second legacy LayeredSkeletonRig on top of the
# player's production rig, so neither the selected skin nor joint alignment
# could be evaluated reliably.
func _enter_tree() -> void:
	var rig := get_node_or_null("Player/ProfessionSkeletonRig")
	assert(rig is ProfessionSkeletonCharacter, "Demo is missing the production humanoid rig")
	var humanoid_rig := rig as ProfessionSkeletonCharacter
	humanoid_rig.forced_rig_id = "base_armorer"
	humanoid_rig.initial_humanoid_skin = ProfessionSkeletonCharacter.HUMANOID_BASE_SKIN_ID
