extends EntityAI
class_name EntityAIGD

# Copyright Péter Magyar relintai@gmail.com
# MIT License, functionality from this class needs to be protable to the entity spell system

# Copyright (c) 2019-2020 Péter Magyar

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

var _data : Dictionary = {
	"target_aura_spells": {},
	"spells": []
}

func _ready():
	pass

func _on_set_owner():
	if not is_instance_valid(owner):
		return
		
	owner.connect("starget_changed", self, "starget_changed")
		
	if not owner.sentity_data:
		return
		
	var ent_data : EntityData = owner.sentity_data
	
	if not ent_data.entity_class_data:
		return
		
	var class_data : EntityClassData = ent_data.entity_class_data
	
	for i in range(class_data.get_num_spells()):
		var spell : Spell = class_data.get_spell(i)
		
		if spell.spells_cast_on_target_num_get() > 0:
			var aura : Spell = spell.spell_cast_on_target_get(0)
			
			if not _data["target_aura_spells"].has(aura.aura_group):
				_data["target_aura_spells"][aura.aura_group] = []
			
			_data["target_aura_spells"][aura.aura_group].append({ "aura_id": aura.id, "spell_id": spell.id, "rank": spell.rank })
			
			continue
			
		_data["spells"].append(spell.id)
		
	for key in _data["target_aura_spells"]:
		var arr : Array = _data["target_aura_spells"][key]
		
		arr.sort_custom(self, "sort_spells_by_rank")


func _update(delta):
	if owner.ai_state == EntityEnums.AI_STATE_ATTACK:
		attack(delta)

func attack(delta):
	var target : Entity = owner.starget
	
	if target == null:
		owner.ai_state = EntityEnums.AI_STATE_REGENERATE
		return
		
	if owner.cast_is_castings():
		return
	
	var cast : bool = false
	if not owner.gcd_hass():
		var taspellsdict : Dictionary = _data["target_aura_spells"]
		
		for taskey in taspellsdict.keys():
			for tas in taspellsdict[taskey]:
				var spell_id : int = tas["spell_id"]
				
				if not owner.spell_hass_id(spell_id):
					continue
			
				if taskey == null:
					if target.aura_gets_by(owner, tas["aura_id"]) == null and not owner.cooldown_hass(spell_id):
						owner.spell_crequest_cast(spell_id)
						cast = true
						break
				else:
					if target.aura_gets_with_group_by(owner, taskey) == null and not owner.cooldown_hass(spell_id):
						owner.spell_crequest_cast(spell_id)
						cast = true
						break
			if cast:
				break
				
		if not cast:
			var sps : Array = _data["spells"]
		
			for spell_id in sps:
				if not owner.spell_hass_id(spell_id):
					continue
			
				if not owner.cooldown_hass(spell_id):
					owner.spell_crequest_cast(spell_id)
					cast = true
					break
	
	if owner.cast_is_castings():
		return
	
	var dir : Vector2 = target.get_body().get_tile_position() - owner.get_body().get_tile_position()
	var l = dir.length()
	
	if l > 1:
		owner.get_body().move_towards_target()

func sort_spells_by_rank(a, b):
	if a == null or b == null:
		return true
		
	return a["rank"] > b["rank"]

func starget_changed(entity: Entity, old_target: Entity):
	if entity:
		owner.ai_state = EntityEnums.AI_STATE_ATTACK
	else:
		owner.ai_state = EntityEnums.AI_STATE_OFF
