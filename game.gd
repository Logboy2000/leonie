"""
Creative Project Planning
Sing Unburied Sing
Logan H
Instructions: https://drive.google.com/file/d/1Dk0cbmGLyQIzOQjgIKXvnD-3xlF1Q4h2/view
Product: Video Game
Premise: 
Singleplayer Game where you Play as Leonie who fights between 2 resources: Meth VS Water

Water: 
Healing, Life, Vitality, Hope, Power of life
Makes the game harder at first because seeing true reality is hard
Harder to gain
Slower payoff
Meth: Temporary Comfort, “False Water” (maybe ice?)

Opposites: e.g(70% Meth -> 30% Water)

Game loop:
Short-term stability (meth) creates long-term instability.
Long-term stability (water) creates temporary discomfort.

Questions:
How should other characters play a role? (Pop, Mam, Jojo, Micheal)
Should winning be possible? Theoretically possible to win, just like how Leonie could change but it would require significant change and thinking outside the box to do so. Maybe some cards/items interact in a way with some clever thinking to win?
"""

extends Control
var wait_disabled = false
@onready var root: SubViewportContainer = $"../.."
@onready var meth_bar: ProgressBar = %MethBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var message_label: Label = %MessageLabel
@onready var turn_label: Label = %TurnLabel

@onready var cope_button: Button = %CopeButton
@onready var wait_button: Button = %WaitButton
@onready var reach_button: Button = %ReachButton

var _water := 50.0
var _meth := 50.0

const song_1 = preload("uid://hum8b4btj21e")
const song_3 = preload("uid://xdabnk1up123")
const song_4 = preload("uid://bvlgi7ys1kqai")
const song_5 = preload("uid://ddxn66b3l3jos")
const song_6 = preload("uid://b1nsampb86eij")
const STATIC_SOUND = preload("uid://e4jjmspemugi")

const glitch_sounds = [
	preload("uid://c4ndvqtd46pbp"),
	preload("uid://dydipf0woufe3"),
	preload("uid://b6wbl6suk5bp6")
]

var water: float:
	get:
		return _water
	set(value):
		_water = value
		normalize()

var meth: float:
	get:
		return _meth
	set(value):
		_meth = value
		normalize()

var distortion: float:
	get:
		return root.material.get("shader_parameter/distortion_strength")
	set(value):
		root.material.set("shader_parameter/distortion_strength", value)
		
var chroma: float:
	get:
		return root.material.get("shader_parameter/chroma_strength")
	set(value):
		root.material.set("shader_parameter/chroma_strength", value)


const MAX := 100

var strain := 0 # hidden cost of reaching out
var reach_chain := 0 # consecutive Reach Out uses
var wait_chain := 0
var turn := 0
var turns_since_meth := 0


var typing := false
var type_index := 0
var type_delay := 0.05
var type_timer := 0.0

var current_song = null
var message_history: Array[String] = []
var high_meth_timer := 0.0
var in_recovery_sequence := false
var recovery_mode := false

func _ready() -> void:
	normalize()
	show_message("Leonie, you need to get yourself together.")

func _process(delta):
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		true_win()
	if not typing:
		if meth >= 95 and not in_recovery_sequence and not recovery_mode:
			high_meth_timer += delta
			if high_meth_timer >= 30.0 or wait_disabled == true:
				start_recovery_sequence()
		else:
			high_meth_timer = 0.0
		return
		
	type_timer -= delta
	if type_timer > 0:
		return
		
	if type_index >= message_label.text.length():
		typing = false
		return
		
	type_index += 1
	
	%TextBoop.play()
	message_label.visible_characters = type_index
	
	var current_char := message_label.text[type_index - 1]
	
	match current_char:
		",":
			type_timer = 0.2
		".", "!", "?":
			type_timer = 0.75
		_:
			type_timer = type_delay

func _text_update():
	if message_label.visible_characters < message_label.get_total_character_count():
		message_label.visible_characters += 1

func normalize():
	_water = clamp(_water, 0, 100)
	_meth = clamp(_meth, 0, 100)
	var total = _water + _meth
	_water = int((_water / total) * MAX)
	_meth = MAX - _water
	meth_bar.value = _meth
	distortion = max((meth - 50) / 20, 0)
	chroma = max((meth - 50) / 20, 0)
	update_music()
	update_button_text()

func update_music():
	var target_song = null
	if recovery_mode == true:
		target_song = song_1
	elif meth < 60:
		target_song = song_3
	elif meth < 80:
		glitch()
		target_song = song_4
	elif meth < 95:
		glitch()
		target_song = song_5
	else:
		glitch()
		target_song = song_6
	
	if current_song != target_song:
		current_song = target_song
		Audio.play_music(target_song)

func update_button_text():
	# Cope
	if recovery_mode:
		cope_button.text = "Stay Calm"
		wait_button.text = "Reflect"
		reach_button.text = "Connect"
		return

	if meth >= 95:
		cope_button.text = "Win"
	elif meth >= 90:
		cope_button.text = ["NEED", "NOW", "FIX"].pick_random()
	elif meth >= 60:
		cope_button.text = "Numb"
	elif water >= 80:
		cope_button.text = "Relapse"
	else:
		cope_button.text = "Cope"
	
	# Wait
	if meth >= 95:
		wait_button.text = "Why wait?"
	elif meth >= 90:
		wait_button.text = "......"
	elif meth >= 60:
		wait_button.text = "Zone Out"
	elif water >= 70:
		wait_button.text = "Breathe"
	else:
		wait_button.text = "Wait"
		
	# Reach
	if meth >= 90:
		reach_button.text = "They Know"
	elif strain >= 80:
		reach_button.text = "Too Weak"
	elif meth >= 60:
		reach_button.text = "Risk It"
	elif water >= 70:
		reach_button.text = "Connect"
	else:
		reach_button.text = "Reach Out"
	
	if meth >= 95:
		reach_button.text = "It won't work"
		wait_button.text = "No more waiting"
		%WaitButton.disabled = true
		%ReachButton.disabled = true
		
	if strain >= 90 and not %ReachButton.disabled:
		%ReachButton.disabled = true
		glitch()
		reach_button.text = "It won't work"


func _on_cope_button_pressed() -> void:
	if recovery_mode:
		_water += 3
		_meth -= 3
		normalize()
		strain = 0
		new_turn("recovery_calm")
		return

	meth += 10
	water -= 5
	reach_chain = 0
	turns_since_meth = 0
	new_turn("cope")

func glitch():
	animation_player.play("RESET")
	Audio.play_sound(glitch_sounds.pick_random(), 0.5, 1)
	animation_player.play("glitch")

func _on_wait_button_pressed() -> void:
	if recovery_mode:
		_water += 5
		_meth -= 5
		normalize()
		
		strain = 0
		new_turn("recovery_wait")
		return

	if water > meth:
		water += 2
		strain = max(strain - 5, 0)
	else:
		meth += 2
	reach_chain = 0
	wait_chain += 1
	turns_since_meth += 1
	new_turn("wait")


func _on_reach_button_pressed() -> void:
	if recovery_mode:
		_water += 10
		_meth -= 10
		normalize()
		strain = 0
		show_message("They answer. You speak. It's real.")
		new_turn("recovery_reach")
		return

	var success_chance := 1.0
	# Meth interferes with clarity
	if meth > 60:
		success_chance -= 0.4
	# Repetition feels desperate
	success_chance -= reach_chain * 0.15
	# Emotional exhaustion
	if strain > 60:
		success_chance -= 0.3
	
	var action_result := ""
	if randf() < success_chance:
		water += max(5 - reach_chain, 1)
		# Jojo (High Water) reduces strain cost
		if water >= 40:
			strain += 10
		else:
			strain += 15
		action_result = "reach_success"
	else:
		strain += 10
		action_result = "reach_fail"
	
	reach_chain += 1
	turns_since_meth += 1
	new_turn(action_result)

func new_turn(action: String = ""):
	if water == 100:
		true_win()
		return
	high_meth_timer = 0.0
	update_button_text()
	turn += 1
	turn_label.text = "Turn " + str(turn)
	var options := []

	if recovery_mode:
		match action:
			"recovery_start":
				options = ["You are ready to begin again."]
			"recovery_reach":
				options = ["Connection feels effortless now.", "They are happy to hear from you.", "You feel a sense of belonging.", "The world feels brighter with them in it.", "You feel a sense of peace.", "The path forward is clear.", "You are not alone."
				]
			"recovery_calm":
				options = ["You take a deep breath.", "Steady.", "You are here, now.",
				"You are safe.",
				"The world is quiet.",
				"You are strong.",
				"You are capable.",
				"You are loved."]
			"recovery_wait":
				options = ["You observe the world with clarity.", "You find strength in stillness.",
				"The world reveals its true colors.",
				"You are present, in this moment.",
				"You are learning to trust yourself.",
				"You are growing stronger.",
				"You are finding your way.",
				"You are becoming whole."]
			_:
				options = [
					"The world is sharp and clear.",
					"You feel strong enough to handle this.",
					"Pop and Mam are waiting for you.",
					"Kayla is proud of you."
				]
		show_message(options.pick_random())
		return

	# Action-based context
	match action:
		"cope":
			if meth > 80:
				options.append_array([
					"You didn't need it, but you took it anyway.",
					"Greed or desperation? It feels the same.",
					"The ceiling spins. You took too much."
				])
			elif turns_since_meth > 3:
				options.append_array([
					"The shaking stops instantly.",
					"Finally. Quiet.",
					"It feels like a warm hug, but cold underneath."
				])
			else:
				options.append_array([
					"A quick fix.",
					"You push the feelings away.",
					"Numbness is better than pain."
				])
		"wait":
			if strain > 50:
				options.append_array([
					"You sit in silence, trying to recover.",
					"Doing nothing is exhausting when your mind is racing.",
				])
			elif water > meth:
				options.append_array([
					"You let the moment pass. Clarity returns.",
					"Patience brings a small comfort.",
				])
			else:
				options.append_array([
					"Waiting just makes the craving louder.",
					"You stare at the wall. Time drags.",
				])
		"reach_success":
			if water < 40:
				options.append_array([
					"Someone answers. You don't feel alone right now.",
					"They're still there. A lifeline.",
					"A voice on the other end grounds you."
				])
			elif water < 70:
				options.append_array([
					"Joseph answers. You don't feel alone right now.",
					"Joseph is still there. A lifeline.",
					"Joseph's voice grounds you."
				])
			else:
				options.append_array([
					"Jojo doesn't ask why.",
					"Jojo is just there.",
					"Jojo knows you're trying."
				])
		"reach_fail":
			options.append_array([
				"Nobody hears you.",
				"Nobody wants to try for you",
				"You feel embarrassed for trying.",
				"The phone just rings and rings.",
				"You're on your own.",
				"You're not worth the effort.",
				"Maybe you should stop asking.",
				"You're not strong enough to do this alone."
			])

	# State-based overrides (only if not a reach result, or if critical) (And not recovery)
	if not recovery_mode and not action.begins_with("reach"):
		# Withdrawal
		if turns_since_meth >= 2 and meth < 50:
			options.append_array([
				"Your body is screaming for relief.",
				"Everything hurts more without it.",
				"You feel empty and restless.",
			])
			glitch()
		
		# High meth
		if meth >= 70 and meth < 90:
			options.append_array([
				"This feels easier than thinking.",
				"You can fix it later.",
				"Just get through this moment.",
				"Nothing else matters right now.",
			])
		elif meth >= 90:
			options.append_array([
				"Reality feels distant.",
				"Your thoughts are slipping.",
				"You can't tell what's real anymore.",
			])
		
		# High water
		if water >= 70:
			options.append_array([
				"You feel clearer than before.",
				"Breathing feels easier.",
				"You remember why you care.",
			])

		# High strain
		if strain >= 70:
			options.append_array([
				"You're exhausted from trying.",
				"It's getting harder to ask for help.",
				"You feel like a burden.",
			])
			
		# Character Injections
		# Pop - Authority/Judgment
		if water < 40:
			options.append("You can already hear him sighing.")
			options.append("Someone would be disappointed if they knew.")
		elif meth > 60:
			options.append("You know better.")
			options.append("Get it together.")
		elif water > 70:
			options.append("Pop wouldn't know what to say.")
			options.append("Pop taught you to push through.")

		# Mam - Guilt/Care
		if water < 40:
			options.append("Someone would worry if they saw you like this.")
		elif meth > 60:
			options.append("She doesn't need to know.")
			options.append("You're protecting her.")
		elif water > 70:
			options.append("Mam would sit with you.")
			options.append("You hate that you've scared Mam.")

		# Micheal -> Kayla - Identity
		if water < 40:
			options.append("Michaela wouldn't get it.")
		elif water < 80:
			options.append("Michaela... no, that's not right.")
		else:
			options.append("Kayla would understand.")
			options.append("Kayla knows what it's like to be seen.")
		
		# Imminent danger (Overrides everything)
		if meth >= 95:
			options = [
				"There are no other options... Why would I bother to try anymore?"
			]

	if options.is_empty():
		options = ["Everything feels balanced. For now."]
	
	
	if meth == 100:
		false_win()
		return

	
	# Filter repeats
	var valid_options = []
	for opt in options:
		if not opt in message_history:
			valid_options.append(opt)
	
	if valid_options.is_empty():
		valid_options = options # Fallback if all seen
	
	var selected = valid_options.pick_random()
	message_history.append(selected)
	if message_history.size() > 8:
		message_history.pop_front()
		
	show_message(selected)


func show_message(message: String):
	message_label.text = message
	message_label.visible_characters = 0
	type_index = 0
	type_timer = 0.0
	typing = true


func clear_message():
	message_label.text = ""


func false_win():
	Audio.fade_out_music(5)
	Audio.play_sound(STATIC_SOUND)
	show_message("I did it... But why... I should have waited longer")
	animation_player.play("false_win")
	await animation_player.animation_finished
	$MarginContainer/VBoxContainer/HBoxContainer2/MethBar/MarginContainer/WaterLabel.visible = false
	glitch()
	await animation_player.animation_finished
	Audio.stop_all_sound()
	get_tree().reload_current_scene()


func true_win():
	show_message("I'm still here...")
	type_delay = 0.5
	$MarginContainer/VBoxContainer/HBoxContainer2/MethBar/MarginContainer/MethLabel.visible = false
	animation_player.play("true_win")
	animation_player.play("false_win")
	Audio.fade_out_music(5)
	await animation_player.animation_finished
	get_tree().quit()
	

func start_recovery_sequence():
	in_recovery_sequence = true
	cope_button.visible = false
	wait_button.visible = false
	reach_button.visible = false
	
	var lines = [
		"...",
		"The noise... it's stopping.",
		"I didn't take it.",
		"I'm just breathing.",
		"Pop isn't angry. He's just scared for me.",
		"Mam isn't judging. She's just waiting.",
		"Kayla... I remember who I am.",
		"I can see them clearly now."
	]
	
	for line in lines:
		show_message(line)
		while typing:
			await get_tree().process_frame
		await get_tree().create_timer(2.0).timeout
		
		if meth > 50:
			_meth -= 6
			normalize()
			
	water = 50
	meth = 50
	recovery_mode = true
	in_recovery_sequence = false
	
	cope_button.visible = true
	wait_button.visible = true
	reach_button.visible = true
	%CopeButton.disabled = false
	%WaitButton.disabled = false
	%ReachButton.disabled = false
	
	update_music()
	update_button_text()
	new_turn("recovery_start")
