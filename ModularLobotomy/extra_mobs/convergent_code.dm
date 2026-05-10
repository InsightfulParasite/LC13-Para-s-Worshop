#define PYTHAGOREAN(A,B,C,D) sqrt(((A-B)**2)+((C-D)**2))

/mob/living/simple_animal/hostile/gribble
	name = "gribble"
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "tegu"
	icon_living = "tegu"
	see_in_dark = 4

/mob/living/simple_animal/hostile/gribble/FindTarget(list/possible_targets, HasTargetsList = 0)//Step 2, filter down possible targets to things we actually care about
	. = ..()
	say("FindTarget:possibleTargets:_[length(possible_targets)]_,Result:[. ? "[.]" : "None"]")



/mob/living/simple_animal/hostile/gribble/bibble
	name = "bibble"
	color = "green"
	var/ignore_tag
	var/automated_cycle = 0
	var/list/targ_path = list()
	var/list/obstic_map = list()
	//For easier sorting im making a alist.
	var/alist/map_vars = alist(
		"cent" = "0,0",
		"reset_cooldown" = 0
		)

/mob/living/simple_animal/hostile/gribble/bibble/proc/Test1()
	return length(view(7,get_turf(src)))

/mob/living/simple_animal/hostile/gribble/bibble/proc/Test2()
	return length(block(x - 7, y - 7,z,x + 7, y + 7))

/mob/living/simple_animal/hostile/gribble/bibble/proc/Test3()
	return length(Test2() & Test1())

/mob/living/simple_animal/hostile/gribble/bibble/handle_automated_action()
	automated_cycle++
	if(automated_cycle > 5)
		automated_cycle = 0
		ignore_tag = null
		DrawMap(6)
	return ..()

/mob/living/simple_animal/hostile/gribble/bibble/Goto(target, delay, minimum_distance)
	if(target == src.target)
		approaching_target = TRUE
	else
		approaching_target = FALSE
	var/dist = get_dist(src,target)
	if(dist > 1)
		walk(src,0)
		PathStep(target)
		return
	return ..()

/*
* We draw a map of the area. Just to remember how much traffic there is.
*/
/mob/living/simple_animal/hostile/gribble/bibble/proc/DrawMap(cartography_range = vision_range)
	var/our_tag = "[x],[y]"
	if(our_tag in obstic_map && map_vars["reset_timer"] > world.time)
		//Keep our map if we havent moved that much.
		var/turf/ctr = UnpackIntoTurf(map_vars["cent"])
		var/distance_from_ctr = PYTHAGOREAN(ctr.x,x,ctr.y,y)
		if(distance_from_ctr <= vision_range/2)
			return

	obstic_map.Cut()
	map_vars["cent"] = our_tag
	map_vars["reset_timer"] = world.time + 2 SECONDS
	for(var/turf/T in block(x - cartography_range, y - cartography_range,z,x + cartography_range, y + cartography_range))
		if(!istype(T, /turf/open))
			MarkCoord(T, 10000)
			continue
		//If not open turf its likely a wall.
		var/turf/open/O = T
		MarkCoord(O,0)
		if(O.density)
			MarkCoord(O, 10000)
			continue
		if(istype(O, /turf/open/water/deep))
			var/turf/open/water/deep/watar = O
			if(!watar.safe)
				MarkCoord(watar, 10000)
				continue
		if(O.slowdown)
			MarkCoord(O, O.slowdown)

		//Do not go on forever, stop when we reach critical mass.
		var/total_extra = 0
		/*
		* Lets just get silly with it, a total of 20 items can be checked
		* If one item cycle returns early then we can use the extra charges
		* on the next.
		*/
		var/total_check = 0

		for(var/obj/structure/S in O)
			total_check++
			if(total_extra > 50 || total_check >= 15)
				break
			if(S.density)
				MarkCoord(S, 5)
				total_extra += 5

		for(var/obj/machinery/M in O)
			total_check++
			if(total_extra > 50 || total_check >= 20)
				break
			if(M.density && !istype(M,/obj/machinery/door))
				MarkCoord(M, 5)
				total_extra += 5

		if(total_extra > 50)
			break

		for(var/obj/effect/turf_fire/F in O)
			total_check++
			if(total_check >= 5)
				break
			if(QDELETED(F))
				continue
			MarkCoord(F, 5)

		for(var/mob/living/L in O)
			total_check++
			if(total_check >= 10)
				break
			if(L.density)
				MarkCoord(L, 2)

//Marks the position of the item on the map.
/mob/living/simple_animal/hostile/gribble/bibble/proc/MarkCoord(atom/thing, val)
	if(!thing)
		return
	var/cord_tag = "[thing.x],[thing.y]"
	if(!cord_tag)
		return FALSE
	if(cord_tag in obstic_map)
		obstic_map[cord_tag] += val
		return
	obstic_map += cord_tag
	obstic_map[cord_tag] = val

/mob/living/simple_animal/hostile/gribble/bibble/proc/PathStep(trg)
	//Normal Pathfinding has failed
	if(trg && obstic_map)
		targ_path = list()
		targ_path = FormPath(src,trg)

	if(targ_path && get_dist(src,trg) > 1)
		var/new_turf = popleft(targ_path)
		if(new_turf)
			var/turf/travel_turf = UnpackIntoTurf(new_turf)
			if(travel_turf)
				var/path_dir = get_cardinal_dir(get_turf(src),travel_turf)
				for(var/path in targ_path)
					new /obj/effect/temp_visual/dir_setting/tailsweep(UnpackIntoTurf(path))
				step(src,path_dir)

/mob/living/simple_animal/hostile/gribble/bibble/proc/FormPath(atom/start,atom/end)
	if(!start || !end)
		stack_trace("FormPathFail:1")
		return list()
	var/targ_turf = "[end.x],[end.y]"
	var/our_turf = "[start.x],[start.y]"
	var/last_path_end = our_turf
	var/list/open_f = list()
	var/list/open_h = list()
	var/list/closed_cord = list()
	for(var/i = 1 to 30)
		var/list/temp_list = ReturnOpenCords(last_path_end)
		for(var/cycle in temp_list)
			if(cycle in closed_cord)
				continue
			var/alist/ourl = UnpackCoords(cycle)
			var/gco = PYTHAGOREAN(start.x,ourl["x"],start.y,ourl["y"])
			var/hco = PYTHAGOREAN(end.x,ourl["x"],end.y,ourl["y"])
			//Dont forget the map
			var/fco = gco + hco
			if(cycle != targ_turf)
				fco += obstic_map[cycle]
			//Put all these values into lists.
			if(!(cycle in open_f))
				open_f += cycle
				LAZYADDASSOC(open_f, cycle, fco)
				//This is to hold h and g costs
				if(cycle)
					if(cycle in open_h)
						//Update with new values
						open_h[cycle] = hco
						continue
					open_h += cycle
					LAZYADDASSOC(open_h, cycle, hco)
		closed_cord += last_path_end
		closed_cord[last_path_end] = open_f[last_path_end]
		open_f -= last_path_end

		var/list/lowest_vals = ReturnLowestVals(open_f, open_h)
		if(!length(lowest_vals))
			stack_trace("FormPathFail:2")
			//try that again
			continue

		last_path_end = pick(lowest_vals)
		if(last_path_end == targ_turf)
			break

	MarkTurfs(closed_cord,/obj/effect/temp_visual/sparkles/red)

	var/list/backtrack = Backtrack(last_path_end,our_turf, closed_cord)
	if(!(our_turf in backtrack))
		stack_trace("FormPathFail:3")
		return list(our_turf)
	//The very first turf in the list is the turf the monster is standing on.
	backtrack.Cut(1,2)
	return backtrack

//Walk ourselves backwards
/mob/living/simple_animal/hostile/gribble/bibble/proc/MarkTurfs(list/L, effectpath = /obj/effect/temp_visual/guardian/phase/out)
	//Remove this after
	for(var/turf in L)
		new effectpath(UnpackIntoTurf(turf))


//Walk ourselves backwards
//Is the same as FormPath but simplified
/mob/living/simple_animal/hostile/gribble/bibble/proc/Backtrack(start_tag,end_tag,list/tredded_path)
	if(!length(tredded_path))
		stack_trace("BacktrackFail")
		return
	var/last_path_end = start_tag
	var/list/open_f = list()
	var/list/good_path = list()
	for(var/i = 1 to 30)
		var/list/temp_list = ReturnOpenCords(last_path_end)
		for(var/cycle in temp_list)
			if(cycle in good_path)
				continue
			var/fco = 10000
			if(cycle in tredded_path)
				fco = tredded_path[cycle]
			//Put all these values into lists.
			if(!(cycle in open_f))
				open_f += cycle
				LAZYADDASSOC(open_f, cycle, fco)

		good_path += last_path_end
		open_f -= last_path_end

		var/list/lowest_vals = ReturnLowestVals(open_f, null)
		if(!length(lowest_vals))
			stack_trace("Backtrack:2")
			//try that again
			continue

		last_path_end = pick(lowest_vals)
		//Just add it without checking around it.
		if(last_path_end == end_tag)
			good_path += last_path_end
			break

	var/final_list = reverseList(good_path)
	MarkTurfs(final_list,/obj/effect/temp_visual/sparkles)

	return final_list

//This should return the value with the lowest f and h cost
/mob/living/simple_animal/hostile/gribble/bibble/proc/ReturnLowestVals(list/normal,list/intensive)
	var/lowest_value_item = ReturnLowestValue(normal)
	var/lowest_value_num = normal[lowest_value_item]
	var/list/temp_list_one = list()
	for(var/i in normal)
		if(normal[i] == lowest_value_num)
			temp_list_one += i

	//If there is only one value return that.
	if(length(lowest_value_num) < 2 || !intensive)
		return temp_list_one

	var/list/temp_list_two = list()

	for(var/tag in temp_list_one)
		var/h_mem = intensive[tag]
		temp_list_two += tag
		LAZYADDASSOC(temp_list_two, tag, h_mem)

	return ReturnLowestValue(temp_list_two)

//Checks around us
/mob/living/simple_animal/hostile/gribble/bibble/proc/ReturnOpenCords(turf_tag)
	. = list()
	if(!turf_tag)
		stack_trace("ReturnOpenCordsFail")
		return
	var/alist/tag_coords = UnpackCoords(turf_tag)
	var/tag_x = tag_coords["x"]
	var/tag_y = tag_coords["y"]

	for(var/cycle = 1 to 4)
		//This should give us our N,E,S,W coords.
		var/offsetx = 0
		var/offsety = 0
		var/invert = 1
		//Every odd number is a invert
		if(ISODD(cycle))
			invert = -1
		if(cycle > 2)
			offsetx = 1 * invert
		if(cycle <= 2)
			offsety = 1 * invert
		. += "[tag_x + offsetx],[tag_y + offsety]"

/mob/living/simple_animal/hostile/gribble/bibble/proc/UnpackCoords(turf_tag)
	if(isnum(turf_tag))
		stack_trace("UnpackCoordsFail")
		return FALSE
	if(!turf_tag)
		return
	var/list/splitter = splittext(turf_tag,",")
	var/turfx = splitter[1]
	var/turfy = splitter[2]
	turfx = text2num(turfx)
	turfy = text2num(turfy)

	return alist("x" = turfx, "y" = turfy)

/mob/living/simple_animal/hostile/gribble/bibble/proc/UnpackIntoTurf(turf_tag)
	var/alist/checker = UnpackCoords(turf_tag)
	if(!checker)
		stack_trace("UnpackFail:NULLFAIL:[turf_tag]")
		return get_turf(src)
	if(length(checker) < 2)
		stack_trace("UnpackFail:XYFAIL:[turf_tag]")
		return get_turf(src)
	return locate(checker["x"],checker["y"],z)

#undef PYTHAGOREAN

//---------------------------------------------------

/mob/living/simple_animal/hostile/gribble/ribble
	name = "ribble"
	color = "green"
	var/walk_timer
	var/list/walk_path = list()

/mob/living/simple_animal/hostile/gribble/ribble/Destroy()
	if(walk_timer)
		deltimer(walk_timer)
	return ..()

/mob/living/simple_animal/hostile/gribble/ribble/Goto(target, delay, minimum_distance)
	if(target == src.target)
		approaching_target = TRUE
	else
		approaching_target = FALSE

	var/dist = get_dist(src,target)
	if(dist > 1 && target)
		PathStep(target)
		return
	return ..()

/mob/living/simple_animal/hostile/gribble/ribble/proc/WalkPing(timer_called = FALSE)
	if(QDELETED(src) || stat == DEAD)
		return
	if(client)
		return
	if(!isturf(loc))
		return
	if(TIMER_COOLDOWN_CHECK(src,walk_timer) && !timer_called)
		return
	walk(src,0)

	say("WalkPing[timer_called]")
	var/our_tag = "[x],[y]"
	if(our_tag in walk_path)
		if(timer_called)
			var/walk_tag = walk_path[our_tag]
			if(walk_timer)
				deltimer(walk_timer)
			if(walk_tag == "dest")
				return
			step(src,walk_tag)
		walk_timer = addtimer(CALLBACK(src, PROC_REF(WalkPing), TRUE), move_to_delay, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/gribble/ribble/proc/PathStep(atom/trg)
	var/turf/trg_turf = get_turf(trg)
	if(!trg)
		return
	var/turf/our_turf = get_turf(src)
	FormPath(our_turf,trg_turf)
	WalkPing(FALSE)

/mob/living/simple_animal/hostile/gribble/ribble/proc/FormPath(turf/start,turf/end)
	walk_path = list()
	var/turf/focus_turf = start
	var/list/openf = list()
	var/list/dir_list = list()
	var/list/closed_turfs = list()
	for(var/cycle = 1 to 10)
		if(!focus_turf)
			stack_trace("FormPath:focus_turfmissing:cycle[cycle]")
			return
		var/list/temp_list = ReturnAdjacentTurfs(focus_turf)
		for(var/turf/T in temp_list)
			var/new_dir = get_dir(T,focus_turf)
			if(T in dir_list)
				dir_list[T] = new_dir
			else
				dir_list += T
				dir_list[T] = new_dir
				if(!(T in openf))
					openf += T
				if(openf[T] >= 1000)
					continue
				openf[T] = AppraiseTurf(T,start,end)

		if(focus_turf == end)
			break

		closed_turfs += focus_turf

		if(length(openf))
			var/good_options = openf - closed_turfs
			focus_turf = ReturnLowestValue(good_options)
		for(var/turf/E in openf)
			var/obj/effect/temp_visual/sparkles/S = new(E)
			S.color = "green"


	//Okay well if we havent gotten to our destination consider the last turf the dest
	var/list/temp_list_two = ReturnAdjacentTurfs(focus_turf)
	for(var/turf/T in temp_list_two)
		var/new_dir_two = get_dir(T,focus_turf)
		if(T in dir_list)
			dir_list[T] = new_dir_two
		else
			dir_list += T
			dir_list[T] = new_dir_two

	walk_path = FormatDirections(dir_list, start,focus_turf)
	for(var/i in walk_path)
		var/our_tag = "[walkin_ere.x],[walkin_ere.y]"
		if(!(our_tag in walk_path))
			stack_trace("FormPath:selfmissing")
			break
		var/obj/effect/temp_visual/dir_setting/curse/hand/s = new(walkin_ere,walk_path[our_tag])
		walkin_ere = get_step(walkin_ere, walk_path[our_tag])
		s.color = "red"

/mob/living/simple_animal/hostile/gribble/ribble/proc/FormatDirections(list/dir_list = list(), turf/start, turf/end)
	. = list()
	if(!length(dir_list))
		stack_trace("FormatDirections:NoDirList")
		return

	if(!start || !end)
		stack_trace("FormatDirections:nostartorend")
		return

	for(var/turf/i in dir_list)
		if(i == end)
			new /obj/effect/temp_visual/dir_setting/tailsweep(i)
			continue
		new /obj/effect/temp_visual/dir_setting/slash(i, dir_list[i])

	var/list/return_list = list()
	var/turf/focus_turf = start
	for(var/cycle = 1 to 10)
		if(!(focus_turf in dir_list))
			return return_list
		var/tag_turf = "[focus_turf.x],[focus_turf.y]"
		var/next_dir = dir_list[focus_turf]
		if(!next_dir)
			stack_trace("FormatDirections:[tag_turf]:cycle[cycle]")
			return
		return_list += tag_turf
		return_list[tag_turf] = next_dir
		if(focus_turf == end)
			return_list[tag_turf] = "dest"
			break
		var/turf/new_turf = get_step(focus_turf, next_dir)
		if(tag_turf in walk_path)
			stack_trace("FormatDirections:retracing")
			return return_list
		if(!isturf(new_turf))
			stack_trace("FormatDirections:new_turf_fail")
			return list()
		focus_turf = new_turf

	return return_list

/mob/living/simple_animal/hostile/gribble/ribble/proc/InvertDirection(num)
	switch(num)
		if(NORTH)
			return SOUTH
		if(SOUTH)
			return NORTH
		if(EAST)
			return WEST
		if(WEST)
			return EAST

/mob/living/simple_animal/hostile/gribble/ribble/proc/AppraiseTurf(turf/T, turf/start, turf/end)
	. = 0
	if(T == end)
		return -1
	. += get_dist(T,end) * 10
	. += get_dist(T,start) * 10
	if(T.density || !istype(T, /turf/open))
		return 10000
	//If not open turf its likely a wall.
	var/turf/open/O = T
	if(istype(O, /turf/open/water/deep))
		var/turf/open/water/deep/watar = O
		if(!watar.safe)
			return 10000
	if(O.slowdown)
		. += O.slowdown

	//Do not go on forever, stop when we reach critical mass.
	var/total_extra = 0
	/*
	* Lets just get silly with it, a total of 20 items can be checked
	* If one item cycle returns early then we can use the extra charges
	* on the next.
	*/
	var/total_check = 0

	for(var/obj/structure/S in O)
		total_check++
		if(total_extra > 50 || total_check >= 15)
			break
		if(S.density)
			if(S.resistance_flags & INDESTRUCTIBLE)
				return 10000
			. += 5
			total_extra += 5
			break

	for(var/obj/machinery/M in O)
		total_check++
		if(total_extra > 50 || total_check >= 20)
			break
		if(M.density)
			if(!istype(M,/obj/machinery/door))
				if(M.resistance_flags & INDESTRUCTIBLE)
					return 10000
				. += 10
				total_extra += 10
				break
			. += 2
			total_extra += 2

	if(total_extra > 50)
		return

	for(var/obj/effect/turf_fire/F in O)
		total_check++
		if(total_check >= 5)
			break
		if(QDELETED(F))
			continue
		. += 100 * damage_coeff[FIRE]
		break

	for(var/mob/living/L in O)
		total_check++
		if(total_check >= 10)
			break
		if(L.density)
			. += 1
			break

/mob/living/simple_animal/hostile/gribble/ribble/proc/ReturnAdjacentTurfs(turf/focus_turf)
	var/list/return_list = list()
	//Just give me adjacent turfs
	var/fx = focus_turf.x
	var/fy = focus_turf.y
	var/fz = focus_turf.z
	return_list += block(fx - 1,fy,fz,fx + 1,fy,fz) - focus_turf
	return_list += block(fx,fy -1 ,fz,fx,fy + 1,fz) - focus_turf
	return return_list

//---------------------------------------------------
/mob/living/simple_animal/hostile/gribble/nibble
	name = "nibble"
	color = "red"
	var/ignore_tag

/mob/living/simple_animal/hostile/gribble/nibble/LosePatience()
	if(isliving(target))
		var/mob/living/L = target
		ignore_tag = L.tag
	return ..()

/mob/living/simple_animal/hostile/gribble/nibble/CanAttack(atom/the_target)
	. = ..()
	if(.)
		if(isliving(the_target))
			var/mob/living/L = the_target
			if(L.tag == ignore_tag && get_dist(src,L) > 2)
				return FALSE

/mob/living/simple_animal/hostile/gribble/nibble/ListTargets(max_range = vision_range) //Step 1, find out what we can see
	. = list()
	var/L = 0
	var/I = 0
	var/S = 0
	var/E = 0
	var/dark_vision = see_in_dark + (target ? 5 : 0)
	var/list/raw_turfs = block(targets_from.x - max_range, targets_from.y - max_range,targets_from.z,targets_from.x + max_range, targets_from.y + max_range,targets_from.z)
	var/list/sight = raw_turfs & view(max_range,get_turf(targets_from))
	for(var/turf/T in sight)
		if(isclosedturf(T) || !can_see(targets_from, T))
			S++
			continue
		var/turf_dist = get_dist(targets_from,T)
		if(max_range > dark_vision && turf_dist > dark_vision)
			var/light_amount = T.get_lumcount()
			if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
				S++
				continue
		L++
		for(var/atom/O in T)
			if(O == src)
				E++
				continue
			if(isdead(O) || isprojectile(O) || istype(O,/obj/effect/landmark) || istype(O, /atom/movable/lighting_object))
				E++
				continue
			. += O
			I++
			//to_chat(user, O ? "[O.type]/Time:[world.time]" : "null")
	say("ListTargets|[L]:Turfs/[I]:Objects/[S]:SkippedTurfs/[E]SkippedObj")
