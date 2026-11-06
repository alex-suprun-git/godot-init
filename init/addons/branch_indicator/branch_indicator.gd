@tool
extends EditorPlugin

# Shows which Git branch this project folder is on and switches branches from
# the editor toolbar. The current branch comes from .git/HEAD (cheap, polled);
# git itself only runs when the list opens or a branch is picked.
#
# Picking a branch first fast-forwards it to its upstream, so the switch lands
# on what was merged on GitHub, not on a stale local copy. The switch is then
# refused only for work it would carry over or lose: files whose content
# differs from both the current and the target branch (line endings ignored).
# Leftovers that already match the target are reset to it. After a switch the
# editor restarts without saving, so nothing held in memory is written over the
# new branch's files.

const REFRESH_SECONDS := 2.0

var _picker: OptionButton
var _confirm: ConfirmationDialog
var _notice: AcceptDialog
var _timer: Timer
var _repo_root := ""
var _head_path := ""
var _current := ""
var _target := ""
# Filled when a branch is picked: leftovers that already match the target.
var _reset_files := PackedStringArray()
var _remove_files := PackedStringArray()


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
	var elsewhere := _branches_in_other_worktrees()
	var branches := _git(["for-each-ref", "--sort=-committerdate", "--format=%(refname:short)", "refs/heads"])
	for branch in _lines(branches["output"]):
		_picker.add_item(branch)
		var index := _picker.item_count - 1
		_picker.set_item_metadata(index, branch)
		if branch == _current:
			_picker.select(index)
			_picker.set_item_disabled(index, true)
		elif elsewhere.has(branch):
			# Git allows a branch in one worktree only; offering it would just fail.
			_picker.set_item_text(index, "%s  (open in %s)" % [branch, elsewhere[branch]])
			_picker.set_item_disabled(index, true)


# Branch name -> folder name, for branches checked out in a worktree other than this one.
func _branches_in_other_worktrees() -> Dictionary:
	var result := {}
	var folder := ""
	for line in _lines(_git(["worktree", "list", "--porcelain"])["output"]):
		if line.begins_with("worktree "):
			folder = line.trim_prefix("worktree ")
		elif line.begins_with("branch refs/heads/") and folder.trim_suffix("/") != _repo_root.trim_suffix("/"):
			result[line.trim_prefix("branch refs/heads/")] = folder.get_file()
	return result


func _on_branch_picked(index: int) -> void:
	_target = str(_picker.get_item_metadata(index))
	if _target == _current:
		return
	var update_note := _update_from_upstream(_target)

	# Tracked files with real changes, compared with where we are and where we go.
	var changed := _names(["diff", "HEAD", "--ignore-cr-at-eol", "--name-only"])
	var differ_from_target := _names(["diff", _target, "--ignore-cr-at-eol", "--name-only"])
	var blocking := PackedStringArray()
	_reset_files = PackedStringArray()
	for path in changed:
		if path in differ_from_target:
			blocking.append(path)
		else:
			_reset_files.append(path)
	# Untracked files the target also has: identical ones can go, others block.
	_remove_files = PackedStringArray()
	for path in _names(["ls-files", "--others", "--exclude-standard"]):
		var in_target: String = _git(["rev-parse", "--verify", "--quiet", _target + ":" + path])["output"].strip_edges()
		if in_target == "":
			continue
		if _git(["hash-object", "--", path])["output"].strip_edges() == in_target:
			_remove_files.append(path)
		else:
			blocking.append(path)

	if not blocking.is_empty():
		_show_current()
		_notice.dialog_text = "Not switching: these files have changes that '%s' does not have.\nCommit or stash them first (they may belong to another session).\n\n%s" % [_target, "\n".join(blocking)]
		_notice.popup_centered()
		return
	var leftovers := _reset_files.size() + _remove_files.size()
	_confirm.dialog_text = "Switch to '%s'?%s%s\nThe editor restarts WITHOUT saving: save open scenes and scripts first." % [
		_target,
		"\n" + update_note if update_note != "" else "",
		"\n%d leftover file(s) already match it and are reset." % leftovers if leftovers > 0 else ""]
	_confirm.popup_centered()


func _switch() -> void:
	if not _reset_files.is_empty():
		_git(["checkout", "--"] + Array(_reset_files))
	for path in _remove_files:
		DirAccess.remove_absolute(_repo_root + "/" + path)
	var result := _git(["switch", _target], true)
	if result["code"] != 0:
		_show_current()
		_notice.dialog_text = "git switch failed; the branch was not changed.\n\n" + result["output"]
		_notice.popup_centered()
		return
	EditorInterface.restart_editor(false)


# Fast-forwards a local branch to its upstream without checking it out.
# Returns a line for the confirm dialog when that did not work.
func _update_from_upstream(branch: String) -> String:
	var upstream: String = _git(["rev-parse", "--abbrev-ref", branch + "@{upstream}"])["output"].strip_edges()
	if upstream == "" or not "/" in upstream:
		return ""
	var remote := upstream.get_slice("/", 0)
	var fetch := _git(["fetch", remote, upstream.trim_prefix(remote + "/") + ":" + branch], true)
	if fetch["code"] != 0:
		return "Could not update it from %s (offline or diverged); switching to the local copy." % upstream
	return ""


func _names(arguments: Array) -> PackedStringArray:
	return _lines(_git(arguments)["output"])


# Splits git output into non-empty lines; written with escapes (not literal line
# breaks) and CR-tolerant so it does not depend on the file's or git's line endings.
func _lines(text: String) -> PackedStringArray:
	return text.replace("\r", "").split("\n", false)


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
