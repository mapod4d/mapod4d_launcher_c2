# tool

# class_name

# extends
extends Control

## A brief description of your script.
##
## A more detailed description of the script.
##
## @tutorial:			http://the/tutorial1/url.com
## @tutorial(Tutorial2): http://the/tutorial2/url.com


# ----- signals

# ----- enums

# ----- constants
const VERSION = [10, 0, 0, 0]
const WK_PATH = 'wk'
const UPDATES_PATH = WK_PATH + '/updates'
const FILELUPDATE = "mplu"
const FILEFROMUPDATE = WK_PATH + "/" + FILELUPDATE
const MULTTIV = "https://sv001.mapod4d.it"

# ----- exported variables

# ----- public variables

# ----- private variables
var _base_path = null
var _dir = null
var _server = null
var _clients = []
var _request = null

var _data_launcher = null
var _flag_upd_launcher = false
var _data_updater = null
var _flag_upd_updater = false
var _data_mapod4d = null
var _flag_upd_mapod4d = false

# ----- onready variables
@onready var _button_download = %Download
@onready var _button_update = %Update
@onready var _button_load = %Load
@onready var _button_quit = %Quit
@onready var _label_msg = %Msg
@onready var _h_request_info = $HTTPRequestInfo


# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method

# Called when the node enters the scene tree for the first time.
func _ready():
	_block_istance()
	if OS.has_feature('editor'):
		_base_path = 'test'
	if OS.has_feature('standalone'):
		_base_path = OS.get_executable_path().get_base_dir()	## funzia sicuramente anche in linux

	_button_update.pressed.connect(_on_button_download_pressed)
	_button_update.pressed.connect(_on_button_update_pressed)
	_button_load.pressed.connect(_on_button_load_pressed)
	_button_quit.pressed.connect(_on_button_quit_pressed)

	_h_request_info.request_completed.connect(
			_on_request_info_completed)

	if _base_path == null:
		_button_update.visible = false
	else:
		_build_dirs()
		_check_upd("m4dlauncherc2")


# ----- remaining built-in virtual methods

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	## simple aswer protocol raw implementation
	for client in _clients:
		if client.get_status() == StreamPeerTCP.STATUS_NONE:
			var index = _clients.find(client)
			_clients.remove(index)
	if _server.is_connection_available():
		var client = _server.take_connection()
		_clients.append(client)
	for client in _clients:
		if client.get_available_bytes() >= 1:
			var data = client.get_8()
			var code = "q".to_ascii_buffer()[0]
			if data == code: # 113 q = question
				client.put_string("a") # answer


# ----- public methods

# ----- private methods
## prevent multiple instance
func _block_istance():
	## create server and prevent multiple instance
	_server = TCPServer.new()
	var error = _server.listen(2000, "127.0.0.1")
	if error != OK:
		get_tree().quit()
#	## test on linux
#	var dor = DirAccess.open('.')
#	if dor.file_exists('poppo.lck'):
#		if dor.remove('poppo.lck') == OK:
#			FileAccess.open('aaa', FileAccess.WRITE)
#		else:
#			FileAccess.open('bbb', FileAccess.WRITE)
#			get_tree().quit()
#	poppo = FileAccess.open('poppo.lck', FileAccess.WRITE)


## check launcher version
func _check_launcher_upd():
	var url = MULTTIV + "/api/software/m4dlauncherc2/?format=json"
	var headers = ["Content-Type: application/json"]
	print(url)
	_request = "launcher"
	_h_request_info.request(url, headers, true, HTTPClient.METHOD_GET)


func _check_updater_upd():
	var url = MULTTIV + "/api/software/m4dupdaterc2/?format=json"
	var headers = ["Content-Type: application/json"]
	print(url)
	_request = "updater"
	_h_request_info.request(url, headers, true, HTTPClient.METHOD_GET)


func _check_upd(software: String):
	var url = MULTTIV + "/api/software/" + software + "/?format=json"
	var headers = ["Content-Type: application/json"]
	print(url)
	_request = software
	_h_request_info.request(url, headers, true, HTTPClient.METHOD_GET)


func _on_request_info_completed(result, response_code, headers, body):
	print(str(headers))
	print(str(response_code))
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		match(_request):
			"m4dlauncherc2":
				_data_launcher = json.get_data()
				print(_data_launcher)
				_launcher_upd()
			"m4dupdaterc2":
				_data_updater = json.get_data()
				print(_data_updater)
				_updater_upd()
			"mapod4dc2":
				_data_mapod4d = json.get_data()
				print(_data_mapod4d)
				_mapod4d_upd()
	else:
		print("error " + str(response_code))
		match(_request):
			"m4dlauncherc2":
				_label_msg.text = tr("LAUCHERUPDERROR")


func _launcher_upd():
	if _upd(VERSION[0], VERSION[1], VERSION[2] , VERSION[3], _data_launcher):
		_button_download.disabled = false
		_label_msg.text = tr("LAUCHERUPD")
		_flag_upd_launcher = true
	else:
		_check_upd("m4dupdaterc2")


func _updater_upd():
	_check_upd("mapod4dc2")


func _mapod4d_upd():
	pass


func _upd(
		current_v1: int, current_v2: int, current_v3: int, current_v4: int, 
		data):
	var retVal = false
	if data.v1 > current_v1:
		retVal = true
	else:
		if data.v2 > current_v2:
			retVal = true
		else:
			if data.v3 > current_v3:
				retVal = true
			else:
				if data.v4 > current_v4:
					retVal = true
	return retVal


#func _check_laucher_update_file():
#	if _dir != null:
#		if _dir.file_exists(FILEFROMUPDATE):
#			_button_update.disabled = false
#
### check update file presence
#func _check_updater_update_online():
#	var url = MULTTIV + "/api/software/m4dupdater2/?format=json"
#	var headers = ["Content-Type: application/json"]
#	_h_request_laucher_upd.request(url, headers, true, HTTPClient.METHOD_GET)
#	return false


## build portable structure
func _build_dirs():
	if _base_path != null:
		_dir = DirAccess.open(_base_path)
		_make_dir(WK_PATH)
		_make_dir(UPDATES_PATH)


func _make_dir(path):
	if _dir != null:
		if _dir.dir_exists(path) == false:
			_dir.make_dir(path)


func _load_mapod4d():
	match OS.get_name():
			"Windows", "UWP":
				print("Windows")
			"macOS":
				print("macOS")
			"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				print("Linux/BSD")
			"Android":
				print("Android")
			"iOS":
				print("iOS")
			"Web":
				print("Web")


func _on_button_download_pressed():
	print("download pressed")
	match(_request):
		"m4dlauncherc2":
			print("download m4dlauncherc2")
		"m4dupdaterc2":
			print("download m4dupdaterc2")
		"mapod4dc2":
			print("download mapod4dc2")


func _on_button_update_pressed():
	print("update pressed")
	match(_request):
		"m4dlauncherc2":
			print("update m4dlauncherc2")
		"m4dupdaterc2":
			print("update m4dupdaterc2")
		"mapod4dc2":
			print("update mapod4dc2")
#	var exe = _base_path + WK_PATH + "/updater.exe"
#	print("run " + exe)
#	var pid = OS.create_process(exe, ["++ mapod4du"])
#	if pid == -1:
#		_label_msg.text = tr("CSUPDATER")
#	else:
#		get_tree().quit()


func _on_button_load_pressed():
	print("load pressed")
	_load_mapod4d()


func _on_button_quit_pressed():
	print("quit pressed")
	get_tree().quit()
