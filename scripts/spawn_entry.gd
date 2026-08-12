class_name SpawnEntry
extends RefCounted

enum Kind { NORMAL, JUNK, BOMB }

var kind: Kind = Kind.NORMAL
var level_index: int = 0


static func normal(level_index: int = 0) -> SpawnEntry:
	var entry := SpawnEntry.new()
	entry.kind = Kind.NORMAL
	entry.level_index = level_index
	return entry


static func junk() -> SpawnEntry:
	var entry := SpawnEntry.new()
	entry.kind = Kind.JUNK
	entry.level_index = 0
	return entry


static func bomb() -> SpawnEntry:
	var entry := SpawnEntry.new()
	entry.kind = Kind.BOMB
	entry.level_index = 0
	return entry
