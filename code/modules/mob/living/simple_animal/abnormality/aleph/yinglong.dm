//For getting a checkerboard pattern.
#define GET_CHECKERBOARD_MAP(x,y) (ISEVEN(x) && ISODD(y)) || (ISODD(x) && ISEVEN(y)) ? TRUE : FALSE
//For quickly changing the stance
#define YINGLONG_STANCE_CHANGE(x) stance = x; update_icon()
//Icon stances for telegraphing
#define YINGLONG_IDLE 1
#define YINGLONG_SPARKS 2
#define YINGLONG_BARK 3

//F-02-14-23
/mob/living/simple_animal/hostile/abnormality/yinglong
	name = "Yinglong Dragon"
	desc = "A absurdly large dragon that is craning its neck down while the rest of its body floats above like a wall of clouds."
	icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
	icon_state = "yinglong"
	icon_living = "yinglong"
	portrait = "yinglong"

	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -16
	base_pixel_y = -16
	offsets_pixel_x = list("south" = -32, "north" = -32, "west" = -32, "east" = -32)
	offsets_pixel_y = list("south" = -16, "north" = -16, "west" = -16, "east" = -16)
	occupied_tiles_up = 1

	maxHealth = 4500
	health = 4500
	ranged_cooldown_time = 5
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	ranged = TRUE
	is_flying_animal = TRUE

	threat_level = ALEPH_LEVEL
	can_breach = TRUE
	can_patrol = FALSE
	start_qliphoth = 3
	//TBD
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 0,
		ABNORMALITY_WORK_INSIGHT = list(0, 0, 35, 40, 45),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 50, 55, 55),
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 45, 50, 55),
	)
	work_damage_amount = 10
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride


	ego_list = list(
		/datum/ego_datum/weapon/tarnished,
		/datum/ego_datum/armor/tarnished,
	)
	//gift_type = /datum/ego_gifts/tearstarnished

	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	//Charges for skills
	var/flower_pins = 3
	//Each attack occurs in a certain order
	var/attack_cycle = 1
	//Cooldown for ambient storms
	var/storm_cooldown = 0
	var/storm_cooldown_delay = 10 SECONDS
	//For icon Changes
	var/stance = YINGLONG_IDLE
	//projectile this mob uses in the DecendingPin attack
	var/pin_projectile_type = /obj/projectile/flowerpin
	//Abilities
	var/obj/effect/proc_holder/ability/nix/levin_a
	var/obj/effect/proc_holder/ability/relocate/reloc_a
	//Turfs we can currently effect
	var/list/arena_turfs = list()

/*
* F-02-14-23
*/

/*----------\
|Containment|
\----------*/
//WIP

/mob/living/simple_animal/hostile/abnormality/yinglong/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(breach_type != BREACH_MINING)
		Teleport()

/*-----\
|VITALS|
\-----*/

/mob/living/simple_animal/hostile/abnormality/yinglong/Initialize()
	. = ..()
	levin_a = new()
	src.AddSpell(levin_a)
	reloc_a = new()
	src.AddSpell(reloc_a)

/mob/living/simple_animal/hostile/abnormality/yinglong/Life()
	. = ..()
	if(!.)
		return
	if(IsContained())
		return
	if(length(GLOB.xeno_spawn) && storm_cooldown <= world.time && !target)
		var/list/possible_turf_list = GLOB.xeno_spawn
		//terribly inconvient storms
		for(var/cycle = 1 to 4)
			var/turf/vortex_turf = pick(possible_turf_list)
			if(vortex_turf.z != z)
				break
			var/obj/effect/ambient_danger/dragonvortex/D = new(vortex_turf, faction)
			D.MovePattern()
		storm_cooldown = world.time + storm_cooldown_delay
	return

/mob/living/simple_animal/hostile/abnormality/yinglong/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/yinglong/Destroy()
	if(levin_a)
		QDEL_NULL(levin_a)
	if(reloc_a)
		QDEL_NULL(reloc_a)
	arena_turfs.Cut()
	return ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/update_icon_state()
	. = ..()
	if(stat == DEAD)
		return
	switch(stance)
		if(YINGLONG_IDLE)
			icon_state = "yinglong"
		if(YINGLONG_SPARKS)
			icon_state = "yinglong_s"
		if(YINGLONG_BARK)
			icon_state = "yinglong_a"

/*-----\
|ATTACK|
\-----*/

/mob/living/simple_animal/hostile/abnormality/yinglong/AttackingTarget(atom/attacked_target)
	if(!can_act && !client)
		return
	if(!target)
		GiveTarget(attacked_target)
	if(!isliving(attacked_target) && !ismecha(attacked_target))
		say("BASH")
		return ..()
	return OpenFire()

/mob/living/simple_animal/hostile/abnormality/yinglong/OpenFire()
	if(!can_act)
		return FALSE
	if(ranged_cooldown > world.time)
		return
	ranged_cooldown = world.time + ranged_cooldown_time
	AbilityRoulette(target)
	return

/*
* Wrath of the Inverted Scale: Always consume all Pin charges
* and deal 100 red damage to nearest target.
* (targeting possibly AOE or targeted AOE)
* If target is killed then 60 red damage times consumed
* pin charges is dealt to all enemies within sight. Ouch.
* ---
* The Descending Pin: Basic attack, flower burying pin charge?
* Damage increased with every 2 pin charges.
* ---
* Gathering Rain: Rapid attack for every pin.
* ---
* nix: Scrap or have it consume a charge to inflict rupture.
* ---
* Since body is obscured should we include a baba yaga esque foot stomp?
*/
/mob/living/simple_animal/hostile/abnormality/yinglong/proc/AbilityRoulette(trg = target)
	if(!trg)
		return
	can_act = FALSE
	YINGLONG_STANCE_CHANGE(YINGLONG_BARK)
	if(do_after(src, 2, target = src))
		switch(attack_cycle)
			//Attempt to spawn some pins
			if(-INFINITY to 3)
				DecendingPin(trg)
			if(4)
				DragonVortex()
			if(5)
				GatheringRain(trg)
			if(6)
				nix(trg)
			if(7)
				WrathScale(trg)
				attack_cycle = 0
	YINGLONG_STANCE_CHANGE(YINGLONG_IDLE)
	can_act = TRUE
	attack_cycle++

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/DecendingPin(trg)
	var/obj/projectile/flowerpin/first = DeferProjectile(/obj/projectile/flowerpin/slow, trg, get_turf(src), 8)
	var/first_angle = WRAP(first.Angle - 20, 0 ,360)
	var/angle_change = 0
	for(var/iteration = 1 to 4)
		var/obj/projectile/flowerpin/new_pin = DeferProjectile(pin_projectile_type, trg, get_turf(src), 8 + iteration)
		new_pin.set_angle(WRAP(first_angle + angle_change, 0 ,360))
		//-20, -10, 10, 20
		if(iteration != 2)
			angle_change += 10
			continue
		angle_change += 20

	do_after(src, 8, target = src)

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/GatheringRain(trg)
	var/attack_charges = flower_pins
	var/attack_angle = Get_Angle(src, trg)
	for(var/cycle = 1 to attack_charges)
		if(!do_after(src, 5, target = src))
			break
		if(!trg)
			trg = FindTarget()
			if(!trg)
				break
			attack_angle = Get_Angle(src, trg)
			continue
		for(var/iteration = 1 to 4)
			var/obj/projectile/flowerpin/new_pin = DeferProjectile(pin_projectile_type, trg, get_turf(src), 8 + iteration)
			new_pin.set_angle(WRAP(attack_angle + rand(-30,30), 0 ,360))

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/nix(trg)
	levin_a.Perform(null, src, arena_turfs)

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/WrathScale(trg)
	var/flower_charges = clamp(flower_pins, 1, 4)
	var/fire_angle = 180
	if(flower_charges >= 1)
		for(var/iteration = 1 to 12 * flower_charges)
			var/obj/projectile/flowerpin/hellpin = DeferProjectile(pin_projectile_type, trg, get_turf(src), 10 + iteration)
			fire_angle = WRAP(fire_angle + 30, 0 ,360)
			hellpin.set_angle(fire_angle)

	do_after(src, 10 + (flower_charges * 2), target = src)

	flower_pins = 0

/*--------\
|LOGISTICS|
\--------*/
/mob/living/simple_animal/hostile/abnormality/yinglong/proc/RetrieveArenaTurfs(turf/center)
	. = list()
	for(var/turf/T in  view(9, center))
		if(isfloorturf(T))
			. += T

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/Teleport()
	arena_turfs.Cut()
	reloc_a.Perform(null,src)
	arena_turfs = RetrieveArenaTurfs(get_turf(src))

/*--------\
|ABILITIES|
\--------*/
/mob/living/simple_animal/hostile/abnormality/yinglong/proc/DragonVortex()
	YINGLONG_STANCE_CHANGE(YINGLONG_SPARKS)
	do_after(src, 1.2 SECONDS, target = src)
	var/our_turf = get_turf(src)
	if(!our_turf)
		return
	var/list/directions = GLOB.cardinals.Copy()
	var/list/direction_pattern = FormatPattern()
	var/list/norm_pattern = FormatPatternOrbit()
	var/list/seco_pattern = FormatPatternOrbit(3, TRUE)

	for(var/i = 1 to 4)
		/*
		* Difficult to read but basically thesea
		* two dragon vortexes orbit around
		* the dragon with one orbiting clockwise
		* and the other counter clockwise
		* -IP
		*/
		if(ISEVEN(i))
			var/list/use_pattern = norm_pattern
			var/turf/vortex_turf = our_turf
			if(i == 4)
				use_pattern = seco_pattern
				vortex_turf = locate(x, y - 3, z)
			new /obj/effect/ambient_danger/dragonvortex(vortex_turf, faction, use_pattern)
			continue

		var/turf/deploy = get_step(our_turf, pop(directions))
		if(deploy.density)
			continue
		new /obj/effect/ambient_danger/dragonvortex(deploy, faction, direction_pattern)
	return direction_pattern

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/FormatPattern()
	var/list/return_list = list()
	//Gimme our cords. We arnt going to check anything on the turfs so just cords.
	var/originx = x
	var/originy = y
	for(var/cycle = 1 to 4)
		var/offsetx = 0
		var/offsety = 0
		var/turn_rate = 0
		var/initial_direction = NORTH
		switch(cycle)
			//South
			if(2)
				initial_direction = SOUTH
				offsety = -1
			//East
			if(3)
				initial_direction = EAST
				offsetx = 1
			//West
			if(4)
				initial_direction = WEST
				offsetx = -1
			//North
			else
				offsety = 1
		var/path_direction = initial_direction
		for(var/iteration = 1 to 5)
			var/x_tag = originx + offsetx
			var/y_tag = originy + offsety
			var/turf_tag = "[x_tag],[y_tag]"
			return_list += turf_tag
			turn_rate = turn_rate + 45
			path_direction = turn(initial_direction,turn_rate)
			return_list[turf_tag] = path_direction
			if(path_direction == NORTH || path_direction == NORTHWEST  || path_direction ==  NORTHEAST)
				offsety++
			if(path_direction == SOUTH  || path_direction ==  SOUTHWEST  || path_direction ==  SOUTHEAST)
				offsety--
			if(path_direction == EAST  || path_direction ==  NORTHEAST  || path_direction ==  SOUTHEAST)
				offsetx++
			if(path_direction == WEST  || path_direction ==  NORTHWEST  || path_direction ==  SOUTHWEST)
				offsetx--

	return return_list

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/FormatPatternOrbit(pattern_size = 1, inverse = FALSE)
	var/list/return_list = list()
	var/iteration_mod = 2 * pattern_size
	var/originx = x
	var/originy = y
	//First tile is on us
	var/turf_tag = "[originx],[originy]"
	var/initial_path_dir = SOUTH
	return_list += turf_tag
	return_list[turf_tag] = initial_path_dir
	//Second tile is lower right
	//Redundant but good enough.
	var/path_direction = initial_path_dir
	/*
	* Difficult to explain but ill try -IP
	* The start variables are a initial offset
	* to place the coords we want in the lower right.
	* The next turf x is the coords we will hit next.
	*/
	var/offsetx = (inverse ? -1 : 1) * pattern_size
	var/offsety = -1 * pattern_size
	var/next_turf_x = originx + offsetx
	var/next_turf_y = originy + offsety
	var/next_turf_tag = "[next_turf_x],[next_turf_y]"
	//We will cycle 4 times and make 2 iterations for a total of 8
	for(var/cycle = 1 to 4)
		//These offsets replace the above offset
		offsetx = 0
		offsety = 0
		//We turn the path 90 degrees in either direction to get EAST or WEST
		path_direction = turn(path_direction, path_direction + (inverse ? 90 : -90))
		//If we go these directions offset the coords accordingly.
		if(path_direction == NORTH)
			offsety = 1
		if(path_direction == SOUTH)
			offsety = -1
		if(path_direction == EAST)
			offsetx = 1
		if(path_direction == WEST)
			offsetx = -1
		for(var/iteration = 1 to iteration_mod)
			//Add the tag to the list as a readable coordnate
			return_list += next_turf_tag
			//Assign a direction for the coord that a reader will obey
			return_list[next_turf_tag] = path_direction
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(locate(next_turf_x,next_turf_y,z), path_direction)
			/*
			* Add the offsets for the next coord we mess with.
			* Theoretically this SHOULD do 2 of each direction
			* and create a full square.
			*/
			next_turf_x += offsetx
			next_turf_y += offsety
			next_turf_tag = "[next_turf_x],[next_turf_y]"
	return return_list

/*--\
|NIX|
\--*/
/obj/effect/proc_holder/ability/nix
	name = "Nix"
	desc = "\"Everybodys agony becomes one\" releases a wave of Hatred beams across \
		the area. This attack releases a blessing of the magical girls for your \
		opponent to use."
	action_icon_state = "helper_dash0"
	base_icon_state = "helper_dash"
	cooldown_time = 10 SECONDS
	var/wave_area_halfwidth = 7
	var/wave_area_halfheight = 7
	//How fast between telegraph and beam.
	var/wave_speed = 2
	//The larger the wave delay the longer window someone can jump between the beams.
	var/wave_delay = 2

/obj/effect/proc_holder/ability/nix/can_cast(mob/user = usr)
	if(isabnormalitymob(user))
		var/mob/living/simple_animal/hostile/abnormality/abno = user
		if(abno.IsContained())
			return FALSE
	return ..()

/obj/effect/proc_holder/ability/nix/Perform(target, mob/living/user, area_list)
	. = ..()
	//reset the emergency stop so we are not forever stuck.
	if(!user)
		return

	if(!area_list || !length(area_list))
		area_list = view(get_turf(user))
	ToggleAct(user,FALSE)

	AttackNow(user, area_list)

	AbnoInteraction(user)
	ToggleAct(user,TRUE)

/obj/effect/proc_holder/ability/nix/proc/AttackNow(mob/living/caster, list/arena_turfs)
	if(!caster || !arena_turfs)
		return

	var/caster_x = caster.x
	var/caster_y = caster.y
	var/caster_z = caster.z

	if(length(arena_turfs))
		//Yeah i basically put a buff into oncoming traffic. -IP
		var/thing_to_place = pick(/obj/effect/temp_visual/blessing/qoh,/obj/effect/temp_visual/blessing/kod,
			/obj/effect/temp_visual/blessing/kog,/obj/effect/temp_visual/blessing/sow)
		new thing_to_place(pick(arena_turfs))

	/*
	* Changing this from a left to right wave
	* to a top to bottom requires some math.
	* farthest_y would need to have + wave_area_halfwidth
	* instead of farthest_x.
	* start_turf is the top right while end_turf is
	* bottom left. So move the math alterations from
	* farthest_y to farthest_x with start being +
	* and end being -.
	* Then finally make it
	* farthest_y = farthest_y - 1. -IP
	*/
	var/farthest_x = caster_x - wave_area_halfwidth
	var/farthest_y = caster_y
	var/loop_amt = (wave_area_halfwidth * 2) + 1
	for(var/loop = 1 to loop_amt)
		var/turf/start_turf = locate(farthest_x,farthest_y + wave_area_halfheight,caster_z)
		var/turf/end_turf = locate(farthest_x,farthest_y - wave_area_halfheight,caster_z)
		TelegraphBeam(caster, start_turf, end_turf)
		farthest_x = farthest_x + 1
		if(!do_after(caster, wave_delay, target = caster))
			break


/obj/effect/proc_holder/ability/nix/proc/TelegraphBeam(mob/living/caster, turf/top, turf/bottom)
	var/list/pure_turfs = block(bottom,top)
	//purely visual warning
	//I found this proc while just skimming the online refrence. -IP
	missile(icon('icons/obj/projectiles.dmi', "nihil_heart"),top,bottom)
	for(var/turf/T in pure_turfs)
		if(isopenturf(T))
			FlickOnAtom(T,'icons/effects/cult_effects.dmi',"floorglow_looping",1 SECONDS)
			continue
		pure_turfs -= T

	if(!do_after(caster, wave_speed, target = caster))
		return

	new /datum/beam(top.Beam(bottom, "qoh", time = 3))
	for(var/turf/damage_loc in pure_turfs)
		for(var/mob/living/L in damage_loc)
			if(IsPartOfCreature(caster, L))
				continue
			DamageThing(L, 60, BLACK_DAMAGE, caster, thing_flags = (DAMAGE_FORCED), thing_attack_type = (ATTACK_TYPE_SPECIAL))

//Think about moving this up from subtype to root -IP
/obj/effect/proc_holder/ability/nix/proc/IsPartOfCreature(creature, part)
	if(part == creature)
		return TRUE
	if(istype(part, /mob/living/simple_animal/projectile_blocker_dummy))
		var/mob/living/simple_animal/projectile_blocker_dummy/pbd = part
		if(pbd.parent == creature)
			return TRUE

/*---------------\
|Blessing of Hope|
\---------------*/
/obj/effect/temp_visual/blessing
	name = "blessing of love"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "nihil_heart"
	duration = 10 SECONDS
	var/nice_text = ""
	var/girl_type = /mob/living/simple_animal/hostile/abnormality/hatred_queen

/obj/effect/temp_visual/blessing/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		ApplyEffect(AM)
		qdel(src)

//Overridable Proc
/obj/effect/temp_visual/blessing/proc/ApplyEffect(mob/living/L)
	var/obj/effect/temp_visual/decoy/fading/halfsecond/H = new(get_turf(src), girl_type)
	H.dir = 2
	to_chat(L, span_nicegreen("[nice_text]"))

/obj/effect/temp_visual/blessing/qoh
	color = "RED"
	nice_text = "Your wounds start closing as you feel determined to save the world."

/obj/effect/temp_visual/blessing/qoh/ApplyEffect(mob/living/L)
	L.apply_status_effect(/datum/status_effect/magical_blessing)
	return ..()

/obj/effect/temp_visual/blessing/kod
	name = "blessing of justice"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "nihil_spade"
	color = "blue"
	nice_text = "It feels like someone is softening the attacks against you."
	girl_type = /mob/living/simple_animal/hostile/abnormality/despair_knight

/obj/effect/temp_visual/blessing/kod/ApplyEffect(mob/living/L)
	L.apply_lc_protection(10)
	return ..()

/obj/effect/temp_visual/blessing/kog
	name = "blessing of happiness"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "nihil_diamond"
	color = "gold"
	nice_text = "Your attacks feel energized and you cant help but crack a smile."
	girl_type = /mob/living/simple_animal/hostile/abnormality/greed_king

/obj/effect/temp_visual/blessing/kog/ApplyEffect(mob/living/L)
	L.apply_lc_offense_level_up(10)
	return ..()

/obj/effect/temp_visual/blessing/sow
	name = "blessing of courage"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "nihil_club"
	color = "green"
	nice_text = "You feel brave enough to make more risky hits."
	girl_type = /mob/living/simple_animal/hostile/abnormality/wrath_servant

/obj/effect/temp_visual/blessing/sow/ApplyEffect(mob/living/L)
	L.apply_lc_poise(10)
	return ..()

/*-------------\
|Status Effects|
\-------------*/
	//QOH
/datum/status_effect/magical_blessing
	id = "magical_blessing"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 1 MINUTES
	tick_interval = 10
	alert_type = null
	on_remove_on_mob_delete = TRUE

/datum/status_effect/magical_blessing/on_apply()
	ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, id)
	return TRUE

/datum/status_effect/magical_blessing/tick()
	. = ..()
	if(!ishuman(owner))
		QDEL_IN(src, 5)
		return
	var/mob/living/carbon/human/status_holder = owner
	TickEffect()
	if(status_holder.stat == DEAD)
		qdel(src)

/datum/status_effect/magical_blessing/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, id)

/datum/status_effect/magical_blessing/proc/TickEffect()
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjustSanityLoss(-10)
	status_holder.adjustBruteLoss(-10)

/*-------\
|Relocate|
\-------*/

/obj/effect/proc_holder/ability/relocate
	name = "relocate"
	desc = "Move to another department center."
	action_icon_state = "helper_dash0"
	base_icon_state = "helper_dash"
	cooldown_time = 10 SECONDS

/obj/effect/proc_holder/ability/relocate/can_cast(mob/user = usr)
	if(isabnormalitymob(user))
		var/mob/living/simple_animal/hostile/abnormality/abno = user
		if(abno.IsContained())
			return FALSE
	return ..()

/obj/effect/proc_holder/ability/relocate/Perform(target, mob/living/user)
	. = ..()
	//reset the emergency stop so we are not forever stuck.
	if(!user)
		return
	ToggleAct(user,FALSE)

	Teleport(user)

	AbnoInteraction(user)
	ToggleAct(user,TRUE)

/obj/effect/proc_holder/ability/relocate/proc/Teleport(mob/living/user)
	var/turf/target_turf = FindDestination(user)
	if(!target_turf)
		return
	var/obj/effect/temp_visual/decoy/egress = new(get_turf(user), user)
	animate(egress, pixel_z = 128, alpha = 0, time = 5)

	user.pixel_z = 128
	user.alpha = 0
	user.density = FALSE

	user.forceMove(target_turf)
	sleep(5 SECONDS)
	user.visible_message(span_danger("The ceiling dissapears and [user] leans down from the sky!"))
	animate(user, pixel_z = 0, alpha = 255, time = 10)
	sleep(10)
	var/obj/effect/temp_visual/decoy/D = new(target_turf, user)
	animate(D, alpha = 0, transform = matrix()*2, time = 5)
	user.density = TRUE

	//Cleaner Code Toss meatbags aside
	for(var/mob/living/carbon/human/H in range(1, target_turf))
		if(H.stat >= SOFT_CRIT)
			continue
		user.visible_message("[user] tosses [H] out of the way!")
		H.deal_damage(10, RED_DAMAGE, user)

		var/rand_dir = pick(NORTH, SOUTH, EAST, WEST)
		var/atom/throw_target = get_edge_target_turf(H, rand_dir)
		if(!H.anchored)
			H.throw_at(throw_target, rand(6, 10), 18, H)

/obj/effect/proc_holder/ability/relocate/proc/FindDestination(mob/living/user)
	var/list/teleport_options = GLOB.department_centers
	if(!length(teleport_options))
		return
	return pick(teleport_options)

/*-------------\
|Ambient Danger|
\-------------*/
/obj/effect/ambient_danger/dragonvortex
	name = "dragon vortex"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "drgvortex"
	max_hits = 10
	speed = 5
	damage = 30
	damage_type = WHITE_DAMAGE

/obj/effect/ambient_danger/dragonvortex/Suffer(atom/A)
	. = ..()
	if(!.)
		return
	if(iscarbon(A))
		var/mob/living/carbon/human/H = A
		var/rand_dir = pick(NORTH, SOUTH, EAST, WEST)
		var/atom/throw_target = get_edge_target_turf(H, rand_dir)
		if(!H.anchored)
			H.throw_at(throw_target, 4, 5, H)


#undef GET_CHECKERBOARD_MAP
#undef YINGLONG_STANCE_CHANGE
#undef YINGLONG_IDLE
#undef YINGLONG_BARK
#undef YINGLONG_SPARKS
