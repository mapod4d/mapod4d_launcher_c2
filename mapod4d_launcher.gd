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
const WK_PATH = '/wk'
const UPDATES_PATH = WK_PATH + '/updates'
const UPDATE_FILE = WK_PATH + '/updates/mapod4d.exe'
const FILEFROMUPDATE = WK_PATH + "mplu"

# ----- exported variables

# ----- public variables

# ----- private variables
var _base_path = null
var poppo = null
var server = null
var _clients = []
var _peer_streams = []

# ----- onready variables
@onready var _button_update = %Update
@onready var _button_load = %Load



# ----- optional built-in virtual _init method
#func _init():
#	super._init()
#	#_block_istance()

# ----- built-in virtual _ready method

# Called when the node enters the scene tree for the first time.
func _ready():
	_block_istance()
	if OS.has_feature('editor'):
		_base_path = 'test'
	if OS.has_feature('standalone'):
		_base_path = OS.get_executable_path().get_base_dir()	## funzia sicuramente anche in linux
#	server = TCPServer.new()
#	var error = server.listen(2000, "127.0.0.1")
#	if error != OK:
#		get_tree().quit()


	_button_update.pressed.connect(_on_button_update_pressed)
	_button_load.pressed.connect(_on_button_load_pressed)

	if _base_path == null:
		_button_update.visible = false
	else:
		var dir = _build_dirs()
		_check_updates(dir)

# ----- remaining built-in virtual methods

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# simple aswer protocol raw implementation
	for client in _clients:
		if client.get_status() == StreamPeerTCP.STATUS_NONE:
			var index = _clients.find(client)
			_clients.remove(index)
	if server.is_connection_available():
		var client = server.take_connection()
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
	server = TCPServer.new()
	var error = server.listen(2000, "127.0.0.1")
	if error != OK:
		get_tree().quit()
#	## funzia da provare in linux
#	var dor = DirAccess.open('.')
#	if dor.file_exists('poppo.lck'):
#		if dor.remove('poppo.lck') == OK:
#			FileAccess.open('aaa', FileAccess.WRITE)
#		else:
#			FileAccess.open('bbb', FileAccess.WRITE)
#			get_tree().quit()
#	poppo = FileAccess.open('poppo.lck', FileAccess.WRITE)


## prevent multiple instance
func _answer():
	pass


## build portable structure
func _build_dirs():
	var dir = null
	if _base_path != null:
		dir = DirAccess.open(_base_path)
		_make_dir(dir, _base_path + WK_PATH)
		_make_dir(dir, _base_path + WK_PATH + '/dowload')
		_make_dir(dir, _base_path + WK_PATH + '/dowload/buffer')
		_make_dir(dir, _base_path + WK_PATH + '/ml')
		_make_dir(dir, _base_path + UPDATES_PATH)
	return dir


func _make_dir(dir, path):
	if dir.dir_exists(path) == false:
		dir.make_dir(path)

func _check_updates(dir):
	if dir != null:
		if dir.file_exists(UPDATE_FILE):
			pass


func _on_button_update_pressed():
	print("update pressed")
	var exe = _base_path + WK_PATH + "/updater.exe"
	print(exe)
	var pid = OS.create_process(exe, [])
	get_tree().quit()


func _on_button_load_pressed():
	print("laod pressed")
	_load_mapod4d()


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




