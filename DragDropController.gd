extends Node2D

var current = null
var drag_offset = Vector2()

var candidates = []

export var drag_group = "draggable"
export (bool) var clamp_to_screen = false
export (int) var offset_left = 0
export (int) var offset_right = 64
export (int) var offset_top = 64
export (int) var offset_bottom = 0

onready var screen_size = get_viewport_rect().size


func _ready():
	var draggables = get_tree().get_nodes_in_group(drag_group)
	for dragable in draggables:
		if dragable is CollisionObject2D or dragable is Control:
			dragable.connect("mouse_entered",self,"mouse_entered",[dragable])
			dragable.connect("mouse_exited",self,"mouse_exited",[dragable])
			if dragable is CollisionObject2D:
				dragable.connect("input_event",self,"input_event",[dragable])
			elif dragable is Control:
				dragable.connect("gui_input",self,"input_event_control")

func _process(_delta):
	if current:
		var newPosition = current.get_global_mouse_position() - drag_offset
		
		if clamp_to_screen:
			if newPosition.x > screen_size.x - offset_right:
				newPosition.x = screen_size.x - offset_right
			if newPosition.x < offset_left:
				newPosition.x = offset_left
			if newPosition.y > screen_size.y - offset_top:
				newPosition.y = screen_size.y - offset_top
			if newPosition.y < offset_bottom:
				newPosition.y = offset_bottom
		
		current.set_global_position(newPosition)

func mouse_entered(which):
	candidates.append(which)
	pass

func mouse_exited(which):
	candidates.erase(which)
	pass

func input_event(_viewport: Node, event: InputEvent, _shape_idx: int, _which: Node2D):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.is_pressed():
			candidates.sort_custom(self,"depth_sort")
			var last = null
			if candidates.size() > 0:
				last = candidates.back()
			if last:
				last.raise()
				current = last
				drag_offset = current.get_global_mouse_position() - current.get_global_position()
				if current.has_method("on_drag_start"):
					current.on_drag_start()
		else:
			var can_drop = true
			if current:
				if current.has_method("on_drop"):
					var on_drop_result = current.on_drop()
					can_drop = on_drop_result == null || on_drop_result
				if can_drop:
					current = null

func input_event_control(event: InputEvent):
	input_event(null, event, 0, null)
	

func depth_sort(a, b):
	return b.get_index() < a.get_index()
