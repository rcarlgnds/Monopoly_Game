extends CharacterBody3D


@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")

var jumping = false
var attacks = [
	"Melee_A",
	"Melee_B",
	"Range_A",
	"Range_B"
]
