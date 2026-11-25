extends SceneTree

## Shared harness for every headless suite.
##
## Subclasses implement _run() and call _check() for each assertion. This base
## owns the assertion bookkeeping, the machine-readable RESULT line, and the
## process exit code, so a suite file only contains the scenario itself.
##
## Run one suite:
##   godot --headless --path . --script res://tests/test_core_rules.gd
## Run everything:
##   tests/run_all.bat   (or tests/run_all.sh)

var failures: Array[String] = []
var assertion_count: int = 0


func _initialize() -> void:
	call_deferred("_run_suite")


func _run_suite() -> void:
	await _run()
	_report()


## Override in the suite. Must not call quit() itself.
func _run() -> void:
	push_error("Test suite must override _run()")
	quit(2)


func _check(condition: bool, label: String, detail: String = "") -> void:
	assertion_count += 1
	if condition:
		print("PASS: ", label)
		return
	failures.append(label)
	var suffix: String = "" if detail.is_empty() else "  [" + detail + "]"
	push_error("FAIL: " + label + suffix)


## Prints one parseable line and sets the exit code.
## run_all reads the RESULT line; the exit code is the fallback signal.
func _report() -> void:
	print("RESULT %s assertions=%d failures=%d" % [_suite_name(), assertion_count, failures.size()])
	quit(1 if not failures.is_empty() else 0)


func _suite_name() -> String:
	var path: String = get_script().resource_path
	return path.get_file().get_basename()
