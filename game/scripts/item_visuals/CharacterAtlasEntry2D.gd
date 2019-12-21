extends CharacterAtlasEntry
class_name CharacterAtlasEntry2D

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

export(Rect2) var front_rect : Rect2
export(Rect2) var back_rect : Rect2 
export(Rect2) var right_rect : Rect2
export(Rect2) var left_rect : Rect2

func get_index(facing : int) -> Rect2:
	if facing == CharacterSkeleton2D.CharacterFacing.FACING_FRONT:
		return front_rect
	if facing == CharacterSkeleton2D.CharacterFacing.FACING_BACK:
		return back_rect
	if facing == CharacterSkeleton2D.CharacterFacing.FACING_RIGHT:
		return right_rect
	if facing == CharacterSkeleton2D.CharacterFacing.FACING_LEFT:
		return left_rect
		
	return front_rect
