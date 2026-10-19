class_name Battle
extends Control

signal state_changed(old_state: State, new_state: State)

enum State {
	ACTIVE,
	WAIT,
	PASSIVE,
}

var state: State = State.WAIT


func _ready() -> void:
	_enter_state(state)


func _process(delta: float) -> void:
	match state:
		State.ACTIVE:
			_process_active(delta)
		State.WAIT:
			_process_wait(delta)
		State.PASSIVE:
			_process_passive(delta)


func set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old_state := state
	_exit_state(old_state)
	state = new_state
	_enter_state(new_state)
	state_changed.emit(old_state, new_state)


func _enter_state(s: State) -> void:
	match s:
		State.ACTIVE:
			pass
		State.WAIT:
			pass
		State.PASSIVE:
			pass


func _exit_state(s: State) -> void:
	match s:
		State.ACTIVE:
			pass
		State.WAIT:
			pass
		State.PASSIVE:
			pass


func _process_active(_delta: float) -> void:
	pass


func _process_wait(_delta: float) -> void:
	pass


func _process_passive(_delta: float) -> void:
	pass
