
// A walking terror its mind barely kept together by its superiors.
/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight
	name = "gene corp warbeast"
	desc = "A towering insectoid terror, the only evidence of its human nature being the torn shreds of an employees uniform draped over its shoulders."
	icon = 'ModularTegustation/Teguicons/gcorp_warbeast.dmi'
	icon_state = "gcorp"
	icon_living = "gcorp"
	icon_dead = "gcorp_corpse"
	speak_emote = list("chitters", "buzzes")
	pixel_x = -16
	base_pixel_x = -16
	death_message = "falls to the floor violently spasming before falling still."
	maxHealth = 2500
	health = 2500
	buffed = 5
	rapid_melee = 1
	melee_damage_lower = 50
	melee_damage_upper = 60
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 0.8)
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	death_sound = 'sound/voice/mook_death.ogg'
	butcher_results = list(/obj/item/food/meat/slab/buggy = 2)
	silk_results = list(/obj/item/stack/sheet/silk/steel_advanced = 2)
	var/swat_cooldown = 0
	var/spearhead_cooldown = 0

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/handle_automated_action()
	. = ..()
	if(stat == DEAD)
		return
	if(buffed < 5)
		buffed++

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/bullet_act(obj/projectile/P)
	if(getStaminaLoss() < 30)
		adjustStaminaLoss(5)
	else
		if(prob(20))
			visible_message(span_warning("[src] carefully blocks [P] with its forearms!"))
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!.)
		return
	if(isliving(attacked_target))
		if(buffed >= 2 && swat_cooldown <= world.time)
			SwatAway(attacked_target)
		if(buffed >= 4 && spearhead_cooldown <= world.time)
			Spearhead(attacked_target)

//Attacks
/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/SwatAway(mob/living/L)
	to_chat(L, span_userdanger("[src] swats you away using its forelimbs!"))
	var/turf/thrownat = get_ranged_target_turf_direct(src, L, 4, rand(-10, 10))
	L.throw_at(thrownat, 8, 2, src, TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
	shake_camera(L, 2, 1)
	if(target_memory[L] < 100)
		LoseTarget()
	swat_cooldown = world.time + (4 SECONDS)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/Spearhead(mob/living/L)
	spearhead_cooldown = world.time + (10 SECONDS)
