extends Control

const MATCH_DATA_PATH = "user://match_data/"
const PLAYER_DATA_PATH = "user://player_data/"

var tween_duration = 0.4

@onready var main_container = $MainContainer
@onready var card_list = $MainContainer/CardList
@onready var editor = $MainContainer/Editor
@onready var new_button = $MainContainer/MenuBar/HBoxContainer/NewButton
@onready var menu_bar = $MainContainer/MenuBar
@onready var player_list = $MainContainer/PlayerList
@onready var players_button = $MainContainer/MenuBar/HBoxContainer/PlayersButton

@onready var menu_bar_height = menu_bar.size.y

# Called when the node enters the scene tree for the first time.
func _ready():
	#print(hash(Time.get_datetime_dict_from_system()))
	if OS.get_name() == "Windows":
		#connect("resized", new_button.update_x_position)
		pass
	elif OS.get_name() == "Android":
		resized.connect(_fit_display_cutouts)
		_fit_display_cutouts()
		#card_list.connect("scrolling", _on_card_list_scrolling)
	
	new_button.connect("pressed", _on_new_button_pressed)
	players_button.connect("pressed", _on_players_button_pressed)
	
	card_list.connect("card_edit", _on_card_list_card_edit)
	card_list.connect("card_delete", _on_card_list_card_delete)
	editor.connect("cancel", _on_editor_cancel)
	editor.connect("save", _on_editor_save)
	player_list.connect("cancel", _on_player_list_cancel)
	player_list.connect("save", _on_player_list_save)
	
	load_match_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _fit_display_cutouts():
	main_container.set_position(DisplayServer.get_display_safe_area().position)
	main_container.set_size(DisplayServer.get_display_safe_area().size)
#	new_button.update_x_position()

# Not necessary on Desktop
#func _on_card_list_scrolling(scroll_offset):
#	if scroll_offset == 0:
#		new_button.expand_button()
#	else:
#		new_button.contract_button()

func _on_card_list_card_edit(index):
	open_editor()
	set_edit_index(index)
	editor.load_match_data()
	editor.load_player_data()

func _on_card_list_card_delete(index):
	var saved_match_data = list_match_data()
	if saved_match_data:
		var dir = DirAccess.open(MATCH_DATA_PATH)
		dir.remove(MATCH_DATA_PATH + saved_match_data[index])
		reorder_match_data()

func set_edit_index(index):
	editor.edit_index = index

func _on_editor_cancel():
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir.file_exists("match_data_" + str(editor.edit_index) + ".tres"):
		card_list.delete_card(editor.edit_index)
	close_editor()

func _on_editor_save(edit_index, winning_scores, losing_scores, quota, winning_weights, losing_weights, winning_player_ids, losing_player_ids):
	card_list.set_card_scores(edit_index, winning_scores, losing_scores)
	var match_data = MatchData.new()
	match_data.quota = quota
	match_data.winning_weights = winning_weights
	match_data.losing_weights = losing_weights
	match_data.winning_scores = winning_scores
	match_data.losing_scores = losing_scores
	match_data.winning_player_ids = winning_player_ids
	match_data.losing_player_ids = losing_player_ids
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir:
		DirAccess.open("user://").make_dir("match_data")
	ResourceSaver.save(match_data, MATCH_DATA_PATH + "match_data_" + str(edit_index) + ".tres")
	close_editor()

func _on_player_list_cancel():
	# Discard if not needed
	#var dir = DirAccess.open(PLAYER_DATA_PATH)
	#if not dir.file_exists("player_list.tres"):
	#	card_list.delete_card(editor.edit_index)
	close_player_list()

func _on_player_list_save(names, scores):
	var player_data = PlayerData.new()
	player_data.names = names
	player_data.scores = scores
	var dir = DirAccess.open(PLAYER_DATA_PATH)
	if not dir:
		DirAccess.open("user://").make_dir("player_data")
	ResourceSaver.save(player_data, PLAYER_DATA_PATH + "player_data.tres")
	close_player_list()

func open_editor():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(editor, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", 0.0, tween_duration)
	new_button.disabled = true
#	new_button.hide_button()

func close_editor():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(editor, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", menu_bar_height, tween_duration)
	new_button.disabled = false
#	new_button.show_button()

func open_player_list():
	player_list.load_player_item_list()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(player_list, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", 0.0, tween_duration)
	players_button.disabled = true

func close_player_list():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(player_list, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", menu_bar_height, tween_duration)
	players_button.disabled = false

func list_match_data():
	var saved_match_data = []
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if dir:
		saved_match_data = dir.get_files()
	return saved_match_data

func load_match_data():
	for file in list_match_data():
		var match_data = ResourceLoader.load(MATCH_DATA_PATH + file)
		card_list.load_card(match_data)

func _on_new_button_pressed():
	card_list.add_card()
	new_button.disabled = true

func _on_players_button_pressed():
	open_player_list()
	players_button.disabled = true

func reorder_match_data():
	var dir = DirAccess.open(MATCH_DATA_PATH)
	var saved_match_data = list_match_data()
	for i in saved_match_data.size():
		dir.rename(saved_match_data[i], "match_data_" + str(i) + ".tres")