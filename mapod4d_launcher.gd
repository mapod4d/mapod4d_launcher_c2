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
const M4DVERSION = {
	'v1': 20,
	'v2': 0,
	'v3': 0,
	'v4': 0
}
const M4DNAME = "mapod4d_launcher"

const WK_PATH = 'wk'
const UPDATES_PATH = WK_PATH + '/updates'
const UPDATER = "updater"
const UPDATER_PATH = WK_PATH + "/" + UPDATER
const MULTIVSVR = "https://sv001.mapod4d.it"

# ----- exported variables

# ----- public variables

# ----- private variables
var _base_path = null
var _dir = null
var _server = null
var _clients = []
## request status
var _request = null
var _info = ""
var _exe_ext = ""
var _update_pre = ""

var _data_updater = null
var _data_launcher = null
var _data_mapod4d = null

# ----- onready variables
@onready var _button_download = %Download
@onready var _button_update = %Update
@onready var _button_load = %Load
@onready var _button_quit = %Quit
@onready var _label_msg = %Msg
@onready var _h_request_info = $HTTPRequestInfo
@onready var _h_request_download = $HTTPRequestDowload


# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method

# Called when the node enters the scene tree for the first time.
func _ready():
	_block_istance()
	match OS.get_name():
		"Windows", "UWP":
			_exe_ext = ".exe"
			_update_pre = "w"
		"macOS":
			_update_pre = "m"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			_update_pre = "l"
		"Android":
			_update_pre = "a"
		"iOS":
			_update_pre = "i"
		"Web":
			_update_pre = "e"
	if OS.has_feature('editor'):
		_base_path = 'test/'
	if OS.has_feature('standalone'):
		_base_path = OS.get_executable_path().get_base_dir()

	_button_download.pressed.connect(_on_button_download_pressed)
	_button_update.pressed.connect(_on_button_update_pressed)
	_button_load.pressed.connect(_on_button_load_pressed)
	_button_quit.pressed.connect(_on_button_quit_pressed)

	_h_request_info.request_completed.connect(
			_on_request_info_completed)
	_h_request_download.request_completed.connect(
			_on_request_download_completed)

	if _base_path == null:
		_button_update.visible = false
	else:
		_build_dirs()
		_check_upd("m4dupdaterc2")


# ----- remaining built-in virtual methods
func _enter_tree():
	var args = OS.get_cmdline_user_args()
	print(args)
	if "-m4dver" in args:
		_write_version()
		get_tree().quit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	## download msg
	if _h_request_download.get_http_client_status() == 7:
		var bs = _h_request_download.get_downloaded_bytes() 
		var db = _h_request_download.get_body_size()
		var perc = "%.2f" % 0
		if db > 0:
			perc = "%.2f" % ((float(bs) / float(db)) * 100.0)
		var data = {
			"bs": str(bs),
			"db": str(db),
			"perc": str(perc),
			"info": str(_info)
		}
		
		_label_msg.text = "{info} BS {bs} DB {db} P {perc}".format(data)
		
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
## write version file
func _write_version():
		print(M4DVERSION)
		var json_data = JSON.stringify(M4DVERSION)
		var base_dir = OS.get_executable_path().get_base_dir()
		if OS.has_feature('editor'):
			base_dir = "test"
		var file_name = base_dir + "/" + M4DNAME + ".json"
		print(file_name)
		var file = FileAccess.open(file_name, FileAccess.WRITE)
		if file != null:
			file.store_string(json_data)
			file.flush()


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


## start download update info and set status (_request)
func _check_upd(request: String):
	var url = MULTIVSVR + "/api/software/"
	url += _update_pre + request 
	url += "/?format=json"
	var headers = ["Content-Type: application/json"]
	print(url)
	_request = request
	_h_request_info.request(url, headers, HTTPClient.METHOD_GET)


## end download update info
func _on_request_info_completed(result, response_code, headers, body):
	print(str(headers))
	print(str(response_code))
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		match(_request):
			"m4dupdaterc2":
				_data_updater = json.get_data()
				print(_data_updater)
				_label_msg.text = tr("UPDATERINFOOK")
				_updater_upd()
			"m4dlauncherc2":
				_data_launcher = json.get_data()
				print(_data_launcher)
				_label_msg.text = tr("LAUCHERINFOOK")
				_launcher_upd()
			"mapod4dc2":
				_data_mapod4d = json.get_data()
				print(_data_mapod4d)
				_label_msg.text = tr("MAPOD4DINFOOK")
				_mapod4d_upd()
	else:
		print("error " + str(response_code))
		match(_request):
			"m4dupdaterc2":
				_label_msg.text = tr("UPDATERINFOERROR")
			"m4dlauncherc2":
				_label_msg.text = tr("LAUCHERINFOERROR")
			"mapod4dc2":
				_label_msg.text = tr("MAPOD4DINFOERROR")
		_button_load.disabled = false


## check if "updater" update is required
func _updater_upd():
	var do_download = false
	if _dir != null:
		if _dir.file_exists(UPDATER_PATH + _exe_ext):
			var exit_code = OS.execute(
					_base_path + UPDATER_PATH + _exe_ext, ["++", "-m4dver"])
			print(exit_code)
			if _dir.file_exists(UPDATER_PATH + ".json"):
				var file = FileAccess.open(
					_base_path + UPDATER_PATH + ".json", FileAccess.READ)
				if file != null:
					var data = file.get_as_text()
					var data_json = JSON.parse_string(data)
					if data_json != null:
						if "v1" in data_json and \
							"v2" in data_json and \
							"v3" in data_json and \
							"v4" in data_json:
							if _version_compare(
								data_json.v1, 
								data_json.v2,
								data_json.v3,
								data_json.v4,
								_data_updater
							):
								## updater old download required
								do_download = true
							else:
								## update not required -> next update
								_check_upd("m4dlauncherc2")
						else:
							## updater version invalid download required
							do_download = true
					else:
						## updater version invalid download required
						do_download = true
			
			else:
				## updater file invalid download required
				do_download = true
		else:
			## updater file not found download required
			do_download = true
			
		if do_download:
			_button_download.disabled = false
			_label_msg.text = tr("UPDATERVER")


func _launcher_upd():
	if _version_compare(
			M4DVERSION.v1, M4DVERSION.v2, M4DVERSION.v3, M4DVERSION.v4,
			_data_launcher):
		_button_download.disabled = false
		_label_msg.text = tr("LAUCHERVER")
	else:
		_check_upd("mapod4dc2")


func _mapod4d_upd():
	_button_download.disabled = false
	_label_msg.text = tr("MAPOD4DVER")


## download update, not mapod4d
func _download_upd():
	var ret_val = false
	var url = null
	var download_file = null
	match(_request):
		"m4dupdaterc2":
			download_file = _base_path + UPDATES_PATH + "updater"
			url = _data_updater.link
			_button_download.disabled = true
			_info = tr("UPDATERINFO")
		"m4dlauncherc2":
			download_file = _base_path + UPDATES_PATH + "launcher"
			url = _data_launcher.link
			_button_download.disabled = true
			_info = tr("LAUNCHERINFO")
	print("DOWNLOAD")
	print(download_file)
	print(url)
	if url != null:
		_h_request_download.download_file = download_file
		var error = _h_request_download.request(url)
		if error == OK:
			ret_val = true
	return ret_val


## download update only mapod4d
func _download_mapod4d_upd():
	pass


## end download update
func _on_request_download_completed(result, response_code, headers, body):
	print(str(headers))
	print(str(response_code))
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		match(_request):
			"m4dupdaterc2":
				_data_updater = json.get_data()
				print(_data_updater)
				_button_download.disabled = true
				_button_update.disabled = false
				_label_msg.text = tr("UPDATERDWOK")
			"m4dlauncherc2":
				_data_launcher = json.get_data()
				print(_data_launcher)
				_button_download.disabled = true
				_button_update.disabled = false
				_label_msg.text = tr("LAUCHERDWOK")
			"mapod4dc2":
				_data_mapod4d = json.get_data()
				print(_data_mapod4d)
	else:
		print("error " + str(response_code))
		match(_request):
			"m4dupdaterc2":
				_label_msg.text = tr("UPDATERDWERROR")
			"m4dlauncherc2":
				_label_msg.text = tr("LAUCHERDWERROR")
			"mapod4dc2":
				_label_msg.text = tr("MAPOD4DDWERROR")
		_button_load.disabled = false


func _do_updater_update():
	var ret_val = false
	if _dir != null:
		if _dir.file_exists(UPDATER_PATH + _exe_ext):
			_dir.remove(UPDATER_PATH + _exe_ext)
		if _dir.file_exists(UPDATES_PATH + "updater"):
			var error = _dir.rename(
					UPDATES_PATH + "updater",
					UPDATER_PATH + _exe_ext)
			if error == OK:
				ret_val = true
	return ret_val


func _version_compare(
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
		"m4dupdaterc2":
			print("download m4dupdaterc2")
			_download_upd()
		"m4dlauncherc2":
			print("download m4dlauncherc2")
			_download_upd()
			_button_download.disabled = true
			_button_update.disabled = false
			_label_msg.text = tr("LAUNCHERUPDDW")
		"mapod4dc2":
			print("download mapod4dc2")
			_button_download.disabled = true
			_button_update.disabled = false
			_label_msg.text = tr("MAPOD4DUPDDW")


func _on_button_update_pressed():
	print("update pressed")
	match(_request):
		"m4dupdaterc2":
			print("update m4dupdaterc2")
			_button_update.disabled = true
			if _do_updater_update():
				_label_msg.text = tr("UPDATEROK")
				_check_upd("m4dlauncherc2")
			else:
				_label_msg.text = tr("UPDATERERROR")
		"m4dlauncherc2":
			print("update m4dlauncherc2")
			_button_update.disabled = true
			_label_msg.text = tr("LAUNCHEROK")
			## run updater
			get_tree().quit()
		"mapod4dc2":
			print("update mapod4dc2")
			_button_update.disabled = true
			_label_msg.text = tr("MAPOD4DUPDOK")
			_button_load.disabled = false

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
