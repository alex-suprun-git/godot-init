@tool
extends EditorPlugin

# Shows which Git branch this project folder is on and switches branches from
# the editor toolbar. The current branch comes from .git/HEAD (cheap, polled);
# git itself only runs when the list opens or a branch is picked.
#
# A switch is refused while tracked files have real changes (line-ending-only
# changes are ignored), so another session's uncommitted work is never carried
# or lost. After a switch the editor restarts without saving, so nothing held
# in memory is written over the new branch's files.

const REFRESH_SECONDS := 2.0

var _picker: OptionButton
var _confirm: ConfirmationDialog
var _notice: AcceptDialog
var _timer: Timer
var _repo_root := ""
var _head_path := ""
var _current := ""
var _target := ""


func _enter_tree() -> void:
	_find_repo(ProjectSettings.globalize_path("res://"))
	_picker = OptionButton.new()
	_picker.flat = true
	_picker.fit_to_longest_item = false
	_picker.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	_picker.get_popup().about_to_popup.connect(_fill_branches)
	_picker.item_selected.connect(_on_branch_picked)
	add_control_to_container(CONTAINER_TOOLBAR, _picker)

	_confirm = ConfirmationDialog.new()
	_confirm.confirmed.connect(_switch)
	_confirm.canceled.connect(_show_current)
	_notice = AcceptDialog.new()
	_notice.title = "Branch switch"
	EditorInterface.get_base_control().add_child(_confirm)
	EditorInterface.get_base_control().add_child(_notice)

	_timer = Timer.new()
	_timer.wait_time = REFRESH_SECONDS
	_timer.timeout.connect(_refresh)
	add_child(_timer)
	_timer.start()
	_refresh()


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, _picker)
	_picker.queue_free()
	_confirm.queue_free()
	_notice.queue_free()
	_timer.queue_free()


func _refresh() -> void:
	if _head_path == "":
		_current = ""
	else:
		var head := FileAccess.get_file_as_string(_head_path).strip_edges()
		_current = head.trim_prefix("ref: refs/heads/") if head.begins_with("ref: ") else "detached " + head.left(7)
	if not _picker.get_popup().visible:
		_show_current()


# Collapses the button to the one current branch; the full list is read on open.
func _show_current() -> void:
	_picker.clear()
	_picker.add_item("git: " + _current if _current != "" else "no git")
	_picker.select(0)
	_picker.tooltip_text = "Git HEAD: " + _head_path + "\nClick to switch branch."


func _fill_branches() -> void:
	if _repo_root == "":
		return
	_picker.clear()
	var branches := _git(["for-each-ref", "--sort=-committerdate", "--format=%(refname:short)", "refs/heads"])
	for branch in branches["output"].split("\n", false):
		_picker.add_item(branch)
		if branch == _current:
			_picker.select(_picker.item_count - 1)
			_picker.set_item_disabled(_picker.item_count - 1, true)


func _on_branch_picked(index: int) -> void:
	_target = _picker.get_item_text(index)
	if _target == _current:
		return
	var dirty: String = _git(["diff", "HEAD", "--ignore-cr-at-eol", "--name-only"])["output"].strip_edges()
	if dirty != "":
		_show_current()
		_notice.dialog_text = "Not switching: these files have uncommitted changes.\nCommit or stash them first (they may belong to another session).\n\n" + dirty
		_notice.popup_centered()
		return
	_confirm.dialog_text = "Switch to '%s'?\nThe editor restarts WITHOUT saving: save open scenes and scripts first." % _target
	_confirm.popup_centered()


func _switch() -> void:
	var result := _git(["switch", _target], true)
	if result["code"] != 0:
		_show_current()
		_notice.dialog_text = "git switch failed; nothing was changed.\n\n" + result["output"]
		_notice.popup_centered()
		return
	EditorInterface.restart_editor(false)


# stderr stays out unless asked for: git prints a line-ending warning per file there.
func _git(arguments: Array, with_errors: bool = false) -> Dictionary:
	var output := []
	var code := OS.execute("git", PackedStringArray(["-C", _repo_root] + arguments), output, with_errors)
	return {"code": code, "output": "".join(output)}


# Walks up from the project folder to the repository. In a worktree `.git` is a
# file that points at the real git dir ("gitdir: <path>").
func _find_repo(from: String) -> void:
	var dir := from.trim_suffix("/")
	while dir != "":
		var dot_git := dir + "/.git"
		if DirAccess.dir_exists_absolute(dot_git):
			_repo_root = dir
			_head_path = dot_git + "/HEAD"
			return
		if FileAccess.file_exists(dot_git):
			var git_dir := FileAccess.get_file_as_string(dot_git).strip_edges().trim_prefix("gitdir: ")
			if git_dir.is_relative_path():
				git_dir = dir + "/" + git_dir
			_repo_root = dir
			_head_path = git_dir + "/HEAD"
			return
		var parent := dir.get_base_dir()
		if parent == dir:
			return
		dir = parent
