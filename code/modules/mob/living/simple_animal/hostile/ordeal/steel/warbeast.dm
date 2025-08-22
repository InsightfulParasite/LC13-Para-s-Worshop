
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
	var/evicerate_cooldown = 0
	var/behavior = 0


/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_STRONG_GRABBER, "initialize")

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/handle_automated_action()
	. = ..()
	if(stat == DEAD)
		return
	if(buffed < 5)
		buffed++

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/Move()
	if(behavior == 1 || behavior == 2)
		return FALSE
	..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/bullet_act(obj/projectile/P)
	if(getStaminaLoss() < 30)
		//I keep using stamina loss as a mechanic -IP
		adjustStaminaLoss(5)
	else
		if(behavior != 1 || behavior != 2)
			if(prob(20))
				visible_message(span_warning("[src] blocks [P]!"))
			flick("gcorp_def", src)
			return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/update_icon_state()
	if(behavior == 1 || behavior == 2)
		icon_state = "gcorp_spearhead"
		return
	icon_state = "gcorp"

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!. || behavior == 1 || behavior == 2)
		return
	if(isliving(attacked_target))
		if(buffed >= 5 && evicerate_cooldown <= world.time)
			Evicerate(attacked_target)
			return
		if(buffed >= 4 && spearhead_cooldown <= world.time)
			Spearhead(attacked_target)
			return
		if(buffed >= 2 && swat_cooldown <= world.time)
			SwatAway(attacked_target)
			return

//Attacks
/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/SwatAway(mob/living/L)
	to_chat(L, span_userdanger("[src] swats you away using its forelimbs!"))
	var/turf/thrownat = get_ranged_target_turf_direct(src, L, 4, rand(-10, 10))
	L.throw_at(thrownat, 8, 2, src, TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
	shake_camera(L, 2, 1)
	if(target_memory[L] < 100)
		LoseTarget()
	swat_cooldown = world.time + (12 SECONDS)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/Spearhead(mob/living/L)
	behavior = 1
	update_icon()

	//Stolem from big wolf -IP
	do_shaky_animation(2)
	if(do_after(src, 2 SECONDS, target = src))
		var/turf/wallcheck = get_turf(src)
		var/enemy_direction = get_dir(src, get_turf(L))
		for(var/i = 0 to 3)
			if(get_turf(src) != wallcheck || stat == DEAD)
				break
			wallcheck = get_step(src, enemy_direction)
			if(!ClearSky(wallcheck))
				break
			//without this the attack happens instantly
			SLEEP_CHECK_DEATH(1)
			forceMove(wallcheck)
			playsound(wallcheck, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)
			for(var/turf/T in orange(get_turf(src), 1))
				if(isclosedturf(T))
					continue
				new /obj/effect/temp_visual/slice(T)
				HurtInTurf(T, list(), 10, RED_DAMAGE, null, TRUE, FALSE, TRUE, hurt_structure = TRUE)

	behavior = 0
	update_icon()
	spearhead_cooldown = world.time + (10 SECONDS)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/Evicerate(mob/living/L)
	behavior = 2
	update_icon()

	start_pulling(L)
	visible_message(span_danger("[src] grabs [L]!"), \
			span_userdanger("Your grabbed by [src]!"),
			span_hear("You hear aggressive shuffling!"), COMBAT_MESSAGE_RANGE, src)

	for(var/i = 0 to 7)
		if(L.stat > SOFT_CRIT)
			if(ishuman(L))
				adjustBruteLoss(-50)
			else
				adjustBruteLoss(-15)
			visible_message(span_danger("[src] tears apart [L]!"), \
				span_userdanger("Your torn apart by [src]!"),
				span_hear("You hear wet tearing!"), COMBAT_MESSAGE_RANGE, src)
			L.gib(FALSE,TRUE,TRUE)
			break
		if(do_mob(src, L, (1 SECONDS) - i))
			playsound(loc, attack_sound, 50, TRUE, TRUE)
			L.do_attack_animation(src)
			L.deal_damage(50, RED_DAMAGE)

	behavior = 0
	update_icon()
	evicerate_cooldown = world.time + (10 SECONDS)
