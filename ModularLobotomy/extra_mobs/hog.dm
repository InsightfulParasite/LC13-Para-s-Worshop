/*
* Notes
* The behavior for hogs is wandering randomly
* until they get hungry. If they get too hungry
* they start losing health and cannibalizing
* eachother.
* Their diet is determined by what food flags
* they hate.
* They drop meat based on their size.
*
* A usage i can think of for these mobs is to
* have each of them give their own resource, requiring
* a farm of pigs to feed the wolves.
* P.S. Wolf Sprites were taken from a asteroid mob.
* -IP
*/

/obj/item/paper/fluff/hog
	name = "Ecological Notes"
	info = {"<h1><center>Ecological Notes:</center></h1>	<br>
	Pigs: Produce large quantities of meat. Diet varied but refuses to eat toxic food.<br>
	Wolves: Produces lengths of hide that can be tanned into leather. <br>
	Obligate carnivore, prey on pigs.<br>
	Wasps: Larvae produce regenerative mesh.<br>
	Adult wasps implant larvae into the nearest human sized animal before starving to death.<br>
	Mature wasps feed on fruit while the larvae consume meats.<br>
	Beating hosts to a third of their health forces the larvae to unburrow.<br>"}

/mob/living/simple_animal/hostile/hog
	desc = "A short legged omnivore."
	icon = 'ModularLobotomy/_Lobotomyicons/hog.dmi'
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_emote = list("warbles", "quavers")
	emote_hear = list("snort.")
	emote_see = list("sniffs.", "burps.")
	faction = list("neutral")
	speak_chance = 1
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	speed = 3
	health = 50
	maxHealth = 50
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	gender = PLURAL
	stop_automated_movement = FALSE
	stop_automated_movement_when_pulled = TRUE
	del_on_death = TRUE
	can_be_renamed = TRUE
	search_objects = TRUE
	loot = list(/obj/item/food/meat/slab)
	food_type = list(/obj/item/food/grown/wheat)
	loot = list(/obj/item/food/meat/slab)
	tame_chance = 25
	bonus_tame_chance = 15
	vision_range = 5
	aggro_vision_range = 7
	city_faction = FALSE
	//Charges for reproduction
	var/fertility = 3
	//Time of Initilization
	var/toi = 0
	//Time it takes to reach maturity.
	var/grow_time = 5 MINUTES
	//Max Hunger
	var/max_hunger = 100
	//Chances for traits to be altered
	var/mutation_chance = 25
	//Form juviniles metamorphise into
	var/adult_form
	//Food flags that a creature hates.
	var/foodhatetypes = TOXIC | CLOTH
	//Tags of this creatures offspring
	var/list/offspring_tags = list()
	//This creatures inherited traits
	var/list/traits = list()
	//Possible traits this creature can get
	var/list/potential_traits = list(
		"Deformed" = 5,
		"Strong" = 25,
		"Soft" = 10,
		"Regenerative" = 5)

/*--------*\
|Core Procs|
\---------*/
/mob/living/simple_animal/hostile/hog/Initialize()
	. = ..()
	toi = world.time
	update_icon_state()
	set_nutrition(max_hunger)

/mob/living/simple_animal/hostile/hog/examine(mob/user)
	. = ..()
	if(gender == MALE)
		. += span_notice("This is one is male.")
	else if(gender == FEMALE)
		. += span_notice("This is one is female.")
	else
		. += span_notice("You cant identify this creatures sex.")

	if(length(offspring_tags))
		. += span_notice("This creature has had [length(offspring_tags)] offspring.")
	var/examine_text = "This creature is:"
	for(var/i in traits)
		examine_text += " [i],"


/mob/living/simple_animal/hostile/hog/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/newspaper))
		if(!stat)
			user.visible_message(span_notice("[user] baps [name] on the nose with the rolled up [O]."))
			return
	return ..()

/mob/living/simple_animal/hostile/hog/update_icon_state()
	. = ..()
	if(base_icon_state)
		icon_living = "[base_icon_state][mob_size][gender != MALE ? "_f" : ""]"

		if(stat != DEAD)
			icon_state = icon_living

/*----------*\
|Living Procs|
\-----------*/

/mob/living/simple_animal/hostile/hog/Life()
	. = ..()
	if(!.)
		return
	if(!isliving(loc))
		if(nutrition > 0)
			adjustHealth(-1)
			adjust_nutrition(-1)
		else
			if(max_hunger > -1)
				var/regen_amt = 1
				if("Regenerative" in genes)
					regen_amt = 3
				adjustHealth(regen_amt)

	if(adult_form)
		var/lifetime = world.time - toi
		if((lifetime >= grow_time/2 && mob_size == MOB_SIZE_TINY) || (lifetime >= grow_time && mob_size == MOB_SIZE_SMALL))
			growUp()
			return

	//Reproduce
	if(fertility > 0 && nutrition >= 50)
		make_babies()

/mob/living/simple_animal/hostile/hog/handle_automated_movement()
	if(!target)
		var/behavior_type = roll("1d20")
		switch(behavior_type)
			if(1 to 15)
				//walk_rand causes the entity to move in random directions even in space.
				step_rand(src,3)
			else
				walk(src, 0)

/mob/living/simple_animal/hostile/hog/AttackingTarget(atom/attacked_target)
	if(istype(attacked_target, /obj/item/food)) //we eats
		var/obj/item/food/snack = attacked_target
		if(foodhatetypes & snack.foodtypes)
			return
		adjust_nutrition(30)
		playsound(get_turf(src), 'sound/items/eatfood.ogg', 10, 3, 3)
		qdel(attacked_target)
		return
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(L.stat == DEAD && L.health <= (-L.maxHealth/2))
			adjust_nutrition(30)
			L.gib(TRUE, TRUE, TRUE)
			LoseAggro()
			return
	if(istype(attacked_target, /obj/structure/flora/ash/garden))
		var/obj/structure/flora/ash/garden/G = attacked_target
		G.harvest()
		return
	return ..()

/mob/living/simple_animal/hostile/hog/make_babies()
	. = ..()
	if(.)
		fertility--
		var/mob/living/L = .
		offspring_tags += L.tag
		if(istype(L, /mob/living/simple_animal/hostile/hog))
			var/mob/living/simple_animal/hostile/hog/H
			H.InheritTraits(genes, potential_traits, mutation_chance)

/*---------\
|Targetting|
\---------*/
/mob/living/simple_animal/hostile/hog/Found(atom/A)
	. = ..()
	if(.)
		return
	//RAGE
	if(target_memory[A] > 10)
		return TRUE

	if(nutrition <= max_hunger)
		if(istype(A, /obj/item/food))
			var/obj/item/food/snack = A
			if(!(foodhatetypes & snack.foodtypes))
				return TRUE

		if(istype(A, /obj/structure/flora/ash/garden) && !(initial(foodhatetypes) & VEGETABLES))
			var/obj/structure/flora/ash/garden/G = A
			if(!G.harvested)
				return TRUE

/mob/living/simple_animal/hostile/hog/CanAttack(atom/the_target)
	. = ..()
	if(.)
		return
	if(see_invisible < the_target.invisibility)//Target's invisible to us, forget it
		return

	if(isliving(the_target) && max_hunger > -1)
		var/mob/living/L  = the_target
		//Target large prey
		var/hunger_req = (L.mob_size == MOB_SIZE_HUMAN ? 60 : 1)
		if(L.tag in offspring_tags)
			hunger_req = 1

		if(ishostile(L))
			var/mob/living/simple_animal/hostile/animal = L
			hunger_req = (animal_species == animal.animal_species ? 1 : hunger_req)

		if(nutrition < hunger_req)
			return TRUE

/*-----------\
|Unique Procs|
\-----------*/
/mob/living/simple_animal/hostile/hog/proc/InheritTraits(list/new_genes,list/potential,mut_chance = 0)
	genes = new_genes.Copy()
	potential_traits = potential.Copy()
	if(prob(mut_chance))
		for(var/i in potential_traits)
			potential_traits[i] += prob(50) ? 1 : -1
			if(i in genes)
				if(prob(5))
					genes -= i
				continue
			var/apply_chance = potential_traits[i]
			if(prob(apply_chance))
				genes += i

	if("Strong" in genes)
		melee_damage_lower += 2

/mob/living/simple_animal/hostile/hog/proc/growUp()
	if(mob_size == MOB_SIZE_TINY)
		mob_size = MOB_SIZE_SMALL
		update_icon()
		return
	var/mob/living/L = new adult_form(get_turf(src))
	mind?.transfer_to(L)
	if(real_name != name)
		L.name = name
	L.gender = gender
	L.set_nutrition(nutrition)
	L.faction = faction
	L.setDir(dir)
	L.Stun(20, ignore_canstun = TRUE)
	L.update_icon_state()
	visible_message(span_notice("[src] grows up into [L]."))
	if(istype(L, /mob/living/simple_animal/hostile/hog))
		var/mob/living/simple_animal/hostile/hog/H = L
		H.InheritTraits(genes,potential_traits)
	qdel(src)

/*---\
|Pigs|
\---*/
/mob/living/simple_animal/hostile/hog/pig
	name = "hog"
	icon_state = "hog"
	icon_living = "hog"
	base_icon_state = "pig"
	mob_size = MOB_SIZE_HUMAN
	density = TRUE
	can_be_held = FALSE
	fertility = 3
	melee_damage_lower = 10
	melee_damage_upper = 15
	animal_species = /mob/living/simple_animal/hostile/hog/pig
	childtype = list(/mob/living/simple_animal/hostile/hog/pig/piglet = 100)

/mob/living/simple_animal/hostile/hog/pig/piglet
	name = "piglet"
	icon_state = "pig0"
	icon_living = "pig0"
	density = FALSE
	can_be_held = TRUE
	mob_size = MOB_SIZE_TINY
	fertility = 0
	melee_damage_lower = 1
	melee_damage_upper = 5
	adult_form = /mob/living/simple_animal/hostile/hog/pig

/mob/living/simple_animal/hostile/hog/pig/Initialize()
	. = ..()
	if(gender == FEMALE)
		max_hunger *= 1.5
		melee_damage_lower = 15
		melee_damage_upper = 20

/mob/living/simple_animal/hostile/hog/pig/drop_loot()
	var/meat_amt = max(1,round(nutrition / 50))
	if(mob_size >= MOB_SIZE_HUMAN)
		meat_amt++
	for(var/cycle = 1 to meat_amt)
		new /obj/item/food/meat/slab(loc)
	return ..()

/*---\
|Wolf|
\---*/
/mob/living/simple_animal/hostile/hog/wolf
	name = "wolf"
	desc = "A carnivorous canine."
	icon_state = "wolf"
	icon_living = "wolf"
	base_icon_state = "wolf"
	mob_size = MOB_SIZE_HUMAN
	density = TRUE
	can_be_held = FALSE
	speak_emote = list("barks", "woofs")
	emote_hear = list("woof.")
	emote_see = list("sniffs.", "sneeze.")
	fertility = 3
	melee_damage_lower = 20
	melee_damage_upper = 25
	loot = list(/obj/item/food/meat/slab, /obj/item/stack/sheet/animalhide/generic)
	food_type = list(/obj/item/food/meat/slab)
	animal_species = /mob/living/simple_animal/hostile/hog/wolf
	childtype = list(/mob/living/simple_animal/hostile/hog/wolf/wolfpup = 100)
	// I love watching videos online of dogs eating pumpkins but this is for balance
	foodhatetypes = GRAIN | TOXIC | DAIRY | CLOTH | VEGETABLES | FRUIT

/mob/living/simple_animal/hostile/hog/wolf/wolfpup
	name = "wolf pup"
	mob_size = MOB_SIZE_SMALL
	density = FALSE
	can_be_held = TRUE
	loot = list(/obj/item/food/meat/slab)
	fertility = 0
	melee_damage_lower = 5
	melee_damage_upper = 10
	adult_form = /mob/living/simple_animal/hostile/hog/wolf

/*---\
|Wasp|
\---*/
/mob/living/simple_animal/hostile/hog/wasp
	name = "wasp"
	desc = "A large parasitic wasp. Fast but brittle."
	icon_state = "wasp"
	icon_living = "wasp"
	gender = NEUTER
	mob_size = MOB_SIZE_HUMAN
	density = TRUE
	can_be_held = FALSE
	speak_emote = list()
	emote_hear = list("buzz.")
	emote_see = list()
	fertility = 3
	is_flying_animal = TRUE
	health = 20
	maxHealth = 20
	melee_damage_lower = 5
	melee_damage_upper = 10
	loot = list(/obj/item/food/meat/slab/xeno)
	food_type = list(/obj/item/food/meat/slab)
	animal_species = /mob/living/simple_animal/hostile/hog/wasp
	childtype = null
	foodhatetypes = GRAIN | TOXIC | DAIRY | CLOTH | VEGETABLES | MEAT

/mob/living/simple_animal/hostile/hog/wasp/Found(atom/A)
	if(fertility > 0)
		if(ishostile(A))
			var/mob/living/simple_animal/hostile/h = A
			if(locate(/mob/living/simple_animal/hostile/hog/wasp/grub) in h)
				return ..()
			if(h.mob_size >= MOB_SIZE_HUMAN && h.mob_biotypes & MOB_ORGANIC && h.health >= h.maxHealth/3)
				return TRUE
		if(iscarbon(A))
			if(!(locate(/mob/living/simple_animal/hostile/hog/wasp/grub) in A))
				Infest(A)
				return
	return ..()

/mob/living/simple_animal/hostile/hog/CanAttack(atom/the_target)
	if(fertility < 1)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/hog/wasp/AttackingTarget(atom/attacked_target)
	if(fertility > 0)
		if(ishostile(attacked_target) && !istype(attacked_target, type))
			var/mob/living/simple_animal/hostile/h = attacked_target
			if(h.mob_size >= MOB_SIZE_HUMAN && h.health >= h.maxHealth/3)
				Infest(h)
				return
		if(iscarbon(attacked_target))
			Infest(attacked_target)
			return

	return ..()

/mob/living/simple_animal/hostile/hog/wasp/proc/Infest(mob/living/host)
	if(!(host.mob_biotypes & MOB_ORGANIC))
		return FALSE
	LoseAggro()
	fertility--
	visible_message(span_notice("[src] lays eggs on [host]."))
	var/mob/living/L = new /mob/living/simple_animal/hostile/hog/wasp/grub(host)
	offspring_tags += L.tag
	return L

/mob/living/simple_animal/hostile/hog/wasp/grub
	name = "grub"
	desc = "Abnormally sized insect larvae. Looks unaccustomed to open air."
	icon_state = "grub"
	icon_living = "grub"
	mob_size = MOB_SIZE_SMALL
	density = FALSE
	can_be_held = TRUE
	emote_hear = list()
	fertility = 0
	is_flying_animal = FALSE
	melee_damage_lower = 0
	melee_damage_upper = 0
	vision_range = 0
	aggro_vision_range = 1
	grow_time = 2 MINUTES
	max_hunger = 1
	loot = list(/obj/item/food/meat/slab/xeno)
	food_type = list(/obj/item/food/meat/slab)
	adult_form = /mob/living/simple_animal/hostile/hog/wasp
	foodhatetypes = GRAIN | TOXIC | DAIRY | CLOTH | VEGETABLES | FRUIT

/mob/living/simple_animal/hostile/hog/wasp/grub/Life()
	. = ..()
	if(!.)
		return
	if(isliving(loc))
		var/mob/living/L = loc
		L.adjust_nutrition(-2)
		adjust_nutrition(1)
		if(L.health < L.maxHealth/3)
			chewOut(loc)

/mob/living/simple_animal/hostile/hog/wasp/grub/handle_automated_movement()
	return

/mob/living/simple_animal/hostile/hog/wasp/grub/growUp()
	if(isliving(loc))
		chewOut(loc)
	return ..()

/mob/living/simple_animal/hostile/hog/wasp/grub/proc/chewOut(mob/living/L)
	if(!isliving(L) || !L)
		return
	src.forceMove(get_turf(L))
	visible_message(span_notice("[src] chews its way out of [L]."))
	if(L.mob_size >= MOB_SIZE_HUMAN)
		L.adjustBruteLoss(20)
		return
	L.gib(FALSE,TRUE,FALSE)
