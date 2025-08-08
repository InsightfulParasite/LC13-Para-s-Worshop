#define LILI_BEHAVIOR_MODE_STEAL 1
#define LILI_BEHAVIOR_MODE_RETURN 2
#define LILI_BEHAVIOR_MODE_ATTACK 3
/mob/living/simple_animal/hostile/lillibag
	name = "lillibag"
	desc = "A large sack made of leather."
	icon = 'ModularTegustation/Teguicons/lilliputian.dmi'
	icon_state = "bag1"
	icon_living = "bag1"
	density = FALSE
	maxHealth = 120
	health = 120
	melee_damage_lower = 0
	melee_damage_upper = 0
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 2, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	stop_automated_movement_when_pulled = TRUE
	search_objects = FALSE
	mob_size = MOB_SIZE_SMALL
	del_on_death = TRUE
	faction = list("hostile")
	var/size = 1
	var/resources = 10
	var/list/followers = list()

/mob/living/simple_animal/hostile/lillibag/FindTarget()
	return FALSE

/mob/living/simple_animal/hostile/lillibag/update_icon_state()
	. = ..()
	icon_state = "bag[size]"

/mob/living/simple_animal/hostile/lillibag/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	//If less than 5 followers and at least 10 resources, spawn a follower
	if(LAZYLEN(followers) < 5 && (resources >= 10 && resources < 50))
		var/mob/living/simple_animal/hostile/lilliputian/stealer = new(get_turf(src))
		resources -= 10
		stealer.home = src
		followers += stealer
	//If 20 items stolen call everyone back and escape.
	if(resources >= 50)
		var/where_is_everyone = FALSE
		for(var/L in followers)
			if(istype(L, /mob/living/simple_animal/hostile/lilliputian))
				var/mob/living/simple_animal/hostile/lilliputian/I = L
				if(QDELETED(I))
					followers -= I
					continue
				I.behavior_mode = LILI_BEHAVIOR_MODE_RETURN
				where_is_everyone = TRUE
				continue
			followers -= L

		if(!where_is_everyone)
			QDEL_IN(src, 2)

//Explode into consumed loot on death.
/mob/living/simple_animal/hostile/lillibag/death(gibbed)
	var/spew_turf = pick(get_adjacent_open_turfs(src))
	for(var/atom/movable/i in contents)
		i.forceMove(spew_turf)
	..()

//Put item in bag and calculate resource gain.
/mob/living/simple_animal/hostile/lillibag/proc/RecieveItem(atom/movable/thing)
	thing.forceMove(src)
	if(isliving(thing))
		resources += 10
	else
		resources += 1

	if(LAZYLEN(contents) >= 4 || resources >= 10)
		size = 2
	if(LAZYLEN(contents) >= 15 || resources >= 30)
		size = 3
	update_icon()

/mob/living/simple_animal/hostile/lilliputian
	name = "lilliputian"
	desc = "A small entity dressed in rags."
	icon = 'ModularTegustation/Teguicons/lilliputian.dmi'
	icon_state = "lilliputian"
	icon_living = "lilliputian"
	environment_smash = TRUE
	density = FALSE
	friendly_verb_continuous = "smacks"
	friendly_verb_simple = "smack"
	faction = list("hostile")
	maxHealth = 10
	melee_damage_lower = 0
	melee_damage_upper = 5
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 2)
	stop_automated_movement_when_pulled = TRUE
	search_objects = TRUE
	mob_size = MOB_SIZE_SMALL
	can_be_held = TRUE
	del_on_death = TRUE
	var/obj/item/held_item
	var/can_act = TRUE
	var/behavior_mode = LILI_BEHAVIOR_MODE_STEAL
	var/behavior_change_cooldown = 0
	var/behavior_change_delay = 3 SECONDS
	var/mob/living/simple_animal/hostile/lillibag/home

/mob/living/simple_animal/hostile/lilliputian/Initialize()
	. = ..()
	AddComponent(/datum/component/swarming)

/mob/living/simple_animal/hostile/lilliputian/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/lilliputian/Life()
	. = ..()
	if(!. || !can_act) // Dead
		return FALSE
	if(behavior_change_cooldown <= world.time && behavior_mode != LILI_BEHAVIOR_MODE_RETURN && !target)
		behavior_change_cooldown = world.time + behavior_change_delay + rand(1,5)
		if(CheckAndCallBackup())
			behavior_mode = LILI_BEHAVIOR_MODE_ATTACK
			return
		behavior_mode = LILI_BEHAVIOR_MODE_STEAL

/mob/living/simple_animal/hostile/lilliputian/FindTarget()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/lilliputian/AttackingTarget()
	if(!can_act)
		return

	if(isitem(target))
		return GrabItem(target)

	if(home)
		if(istype(target, /mob/living/simple_animal/hostile/lillibag))
			if(isliving(pulling) && pulling != home && pulling != src)
				var/mob/living/H = pulling
				home.RecieveItem(H)
			if(held_item)
				home.RecieveItem(held_item)
				held_item = null
				cut_overlays()
			//If returning home just go inside.
			if(behavior_mode == LILI_BEHAVIOR_MODE_RETURN)
				QDEL_IN(src, 1)
				return
			stop_pulling()
			SLEEP_CHECK_DEATH(1)
			LoseTarget()
			return

	//If no home just throw everything in the local trash bin.
	else
		if(istype(target,/obj/machinery/disposal/bin))
			var/obj/machinery/disposal/bin/B = target
			if(isliving(pulling))
				var/mob/living/H = pulling
				if(H.stat != CONSCIOUS)
					B.place_item_in_disposal(H, src)
					stop_pulling()
			if(held_item)
				B.place_item_in_disposal(held_item, src)
				held_item = null
				cut_overlays()
			stop_pulling()
			SLEEP_CHECK_DEATH(1)
			LoseTarget()
			return

	if(isliving(target))
		var/mob/living/L = target
		if(L) //If subject is in crit and is not being pulled by a ally, grab them.
			if(L.stat != CONSCIOUS && !istype(L.pulledby,/mob/living/simple_animal/hostile/lilliputian))
				start_pulling(target)
				SLEEP_CHECK_DEATH(1)
				LoseTarget()
				return
	return ..()

//Targetting Override
/mob/living/simple_animal/hostile/lilliputian/Found(atom/A)
	//If behavior return, only target home.
	switch(behavior_mode)
		if(LILI_BEHAVIOR_MODE_RETURN)
			if(A == home)
				return TRUE

/mob/living/simple_animal/hostile/lilliputian/CanAttack(atom/the_target)
	//If is item and no held item.
	if(isitem(the_target) && !held_item)
		return TRUE
	//If with loot or a body, bring it back to base.
	if((isliving(pulling) || held_item))
		if(home)
			if(the_target == home)
				return TRUE
		if(istype(the_target,/obj/machinery/disposal/bin))
			return TRUE

	//If living and your not pulling anything, and the subject is unconcious, grab em.
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L)
			//If is pulling living or holding a item ignore this thing.
			if(isliving(pulling) || held_item)
				return FALSE
			//If subject is in crit and is not being pulled by a ally, grab them.
			if(L.stat != CONSCIOUS && !istype(L.pulledby,/mob/living/simple_animal/hostile/lilliputian))
				return TRUE
			if(behavior_mode != LILI_BEHAVIOR_MODE_ATTACK)
				return FALSE
	//Return to normal targeting
	return ..()

/mob/living/simple_animal/hostile/lilliputian/death(gibbed)
	if(held_item)
		held_item.forceMove(get_turf(src))
	return ..()

/mob/living/simple_animal/hostile/lilliputian/update_overlays()
	. = ..()
	if(held_item)
		//Grab the item and lift it 20 pixels above their head.
		var/mutable_appearance/new_overlay = mutable_appearance(held_item.icon, held_item.icon_state)
		new_overlay.pixel_y = 20
		. += new_overlay

//If in a swarm attack the enemy.
/mob/living/simple_animal/hostile/lilliputian/proc/CheckAndCallBackup(mob/living/the_target)
	var/list/allies = list()
	for(var/mob/living/simple_animal/hostile/lilliputian/L in view(3, src))
		if(L.stat == DEAD)
			continue
		if(L.target)
			continue
		allies += L
	if(LAZYLEN(allies) >= 2)
		for(var/mob/living/simple_animal/hostile/lilliputian/I in allies)
			if(I)
				I.behavior_mode = LILI_BEHAVIOR_MODE_ATTACK
		return TRUE

/mob/living/simple_animal/hostile/lilliputian/proc/GrabItem(atom/movable/the_target)
	can_act = FALSE
	if(isturf(the_target.loc))
		the_target.forceMove(src)
		held_item = the_target
		update_icon()
	can_act = TRUE

#undef LILI_BEHAVIOR_MODE_STEAL
#undef LILI_BEHAVIOR_MODE_RETURN
#undef LILI_BEHAVIOR_MODE_ATTACK
