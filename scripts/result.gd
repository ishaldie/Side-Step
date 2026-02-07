## Result Type
## A generic result wrapper for operations that can succeed or fail.
## Use this instead of returning bool or using exceptions.
##
## Usage:
##   var result := GameManager.purchase_shoe(2)
##   if result.success:
##       print("Purchased: ", result.value.name)
##   else:
##       print("Error: ", result.error)
class_name Result
extends RefCounted

# =============================================================================
# PROPERTIES
# =============================================================================

## Whether the operation succeeded
var success: bool = false

## The return value (only valid if success is true)
var value  # Variant - can be any type

## Error message (only valid if success is false)
var error: String = ""

## Optional error code for programmatic handling
var error_code: int = 0

# =============================================================================
# CONSTRUCTORS
# =============================================================================

## Creates a successful result with an optional value
static func ok(val = null) -> Result:
	var r := Result.new()
	r.success = true
	r.value = val
	return r


## Creates a failed result with an error message
static func err(message: String, code: int = 0) -> Result:
	var r := Result.new()
	r.success = false
	r.error = message
	r.error_code = code
	return r

# =============================================================================
# UNWRAPPING
# =============================================================================

## Returns the value or crashes if result is an error
## Use only when you're certain the result is ok
func unwrap():
	assert(success, "Attempted to unwrap error result: " + error)
	return value


## Returns the value or a default if result is an error
func unwrap_or(default):
	return value if success else default


## Returns the value or calls a function to get default
func unwrap_or_else(callable: Callable):
	return value if success else callable.call()

# =============================================================================
# CHAINING
# =============================================================================

## Transforms the value if successful, passes through errors
func map(callable: Callable) -> Result:
	if success:
		return Result.ok(callable.call(value))
	return self


## Transforms errors, passes through success
func map_err(callable: Callable) -> Result:
	if not success:
		return Result.err(callable.call(error))
	return self


## Chains another operation that returns a Result
func and_then(callable: Callable) -> Result:
	if success:
		return callable.call(value)
	return self

# =============================================================================
# UTILITIES
# =============================================================================

## Returns true if result is ok and value matches predicate
func is_ok_and(predicate: Callable) -> bool:
	return success and predicate.call(value)


## Returns true if result is error and error matches predicate
func is_err_and(predicate: Callable) -> bool:
	return not success and predicate.call(error)


## Logs error if present and returns self (for chaining)
func log_if_error(category: String = "Result") -> Result:
	if not success:
		push_warning("[%s] %s" % [category, error])
	return self


func _to_string() -> String:
	if success:
		return "Ok(%s)" % str(value)
	return "Err(%s)" % error
