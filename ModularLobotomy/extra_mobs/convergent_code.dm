#define PYTHAGOREAN(A,B,C,D) sqrt(((A-B)**2)+((C-D)**2))

/mob/living/simple_animal/hostile/gribble
	name = "gribble"
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "tegu"
	icon_living = "tegu"
	see_in_dark = 4
/*
/mob/living/simple_animal/hostile/gribble/FindTarget(list/possible_targets, HasTargetsList = 0)//Step 2, filter down possible targets to things we actually care about
	. = ..()
	say("FindTarget:possibleTargets:_[length(possible_targets)]_,Result:[. ? "[.]" : "None"]")
*/


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

//---------------------------------------------------

/mob/living/simple_animal/hostile/gribble/ribble
	name = "ribble"
	color = "purple"
	var/ignore_tag
	var/walk_timer = null
	var/list/walk_path = list()
	//Possibly a terrible attempt at sorting
	var/alist/walk_variables = list(
		//Very generous
		"attempts" = 50,
		"thinking" = FALSE,
		//If we redraw a map when we reach our dest
		"remap_on_dest" = TRUE,
		//Countdown for how many times we keep our map.
		"redraw" = 0,
		//Travels strictly in adjacent tiles
		"no_diagonals" = FALSE,
		//checks closed turfs afterwards to avoid them
		"careful" = TRUE,
		)

/mob/living/simple_animal/hostile/gribble/ribble/LosePatience()
	if(isliving(target))
		var/mob/living/L = target
		ignore_tag = L.tag
	return ..()

/mob/living/simple_animal/hostile/gribble/ribble/CanAttack(atom/the_target)
	. = ..()
	if(. && isliving(the_target))
		var/mob/living/L = the_target
		if(L.tag == ignore_tag && get_dist(src,L) > 2)
			return FALSE

/mob/living/simple_animal/hostile/gribble/ribble/ListTargets(max_range = vision_range) //Step 1, find out what we can see
	. = list()
	var/dark_vision = see_in_dark + (target ? 5 : 0)
	var/list/sight = view(max_range,get_turf(targets_from))
	for(var/turf/T in sight)
		if(isclosedturf(T) || !can_see(targets_from, T))
			continue
		var/turf_dist = get_dist(targets_from,T)
		if(max_range > dark_vision && turf_dist > dark_vision)
			var/light_amount = T.get_lumcount()
			if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
				continue
		for(var/atom/O in T)
			if(O == src)
				continue
			if(isdead(O) || isprojectile(O) || istype(O,/obj/effect/landmark) || istype(O, /atom/movable/lighting_object))
				continue
			. += O

/mob/living/simple_animal/hostile/gribble/ribble/Destroy()
	if(TIMER_COOLDOWN_CHECK(src,walk_timer))
		deltimer(walk_timer)
		return TRUE
	return ..()

//Highly Experimental Pathing Code
/mob/living/simple_animal/hostile/gribble/ribble/Goto(target, delay, minimum_distance)
	if(target == src.target)
		approaching_target = TRUE
	else
		approaching_target = FALSE

	var/dist = get_dist(src,target)
	if(dist > 1 && dist < 10 && target)
		if(PathStep(target))
			walk(src,0)
			return
	deltimer(walk_timer)
	walk_timer = null
	//Onwards with the OLD CODE!
	return ..()

//Summoning the Path
/mob/living/simple_animal/hostile/gribble/ribble/proc/PathStep(atom/trg)
	var/turf/trg_turf = get_turf(trg)
	if(!trg || !trg_turf || walk_variables["thinking"])
		return
	var/turf/our_turf = get_turf(src)
	var/good_path = FALSE
	//true false seems to not play well with alists
	walk_variables["thinking"] = TRUE
	var/our_tag = "[x],[y]"
	var/trg_tag = "[trg.x],[trg.y]"
	var/walk_path_dir = null
	//If our tag is in the map and our targets tag is in the map just reuse.
	if(our_tag in walk_path && trg_tag in walk_path && walk_variables["redraw"] < 2)
		walk_path_dir = walk_path[trg_tag]

	//If our target isnt stationary just keep the map.
	if(walk_path_dir != "dest")
		if(FormPath(trg_turf,our_turf))
			good_path = TRUE

	//To prevent us using the same map forever we will redraw after 2 attempts
	walk_variables["redraw"] += 1

	walk_variables["thinking"] = FALSE
	if(length(walk_path) && good_path)
		WalkPing(0)
		walk_variables["redraw"] = 0
		return TRUE
	//reset redraw counter

//The actual movement that is called over and over.
/mob/living/simple_animal/hostile/gribble/ribble/proc/WalkPing(timer_called = 0)
	if(QDELETED(src))
		return
	if(stat == DEAD)
		walk(src,0)
		return
	if(client)
		return
	if(!isturf(loc))
		return
	//If next to target do not move into them.
	if(get_dist(target,src) <= 1)
		return
	//Give me our xy tag.
	var/our_tag = "[x],[y]"
	var/turf/steppers = get_step(src, walk_path[our_tag])
	var/timer_cooldown = max(1, move_to_delay)
	if(our_tag in walk_path)
		var/walk_tag = walk_path[our_tag]
		deltimer(walk_timer)
		walk_timer = null

		if(walk_tag == "dest")
			//causes "jolts" of movement
			if(target && walk_variables["remap_on_dest"])
				Goto(target, move_to_delay)
			return
		Move(steppers, walk_path[our_tag])
		if(timer_called < 20)
			walk_timer = addtimer(CALLBACK(src, PROC_REF(WalkPing), timer_called + 1), timer_cooldown, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/gribble/ribble/proc/FormPath(turf/start,turf/end)
	walk_path = list()
	var/max_cycles = walk_variables["attempts"] + move_to_delay
	var/turf/focus_turf = start
	var/list/openf = list()
	var/list/dir_list = list()
	var/list/closed_turfs = list()
	for(var/cycle = 1 to max_cycles)
		if(!focus_turf)
			//If no focus_turf then something has gone terribly wrong.
			stack_trace("FormPath:focus_turfmissing:cycle[cycle]:[type]")
			return
		if(get_dist(focus_turf, start) > 20)
			break
		var/list/temp_list = ReturnAdjacentTurfs(focus_turf, walk_variables["no_diagonals"])
		var/list/total_list = openf + closed_turfs
		for(var/turf/T in temp_list)
			var/new_dir = get_dir(T,focus_turf)
			//Replace dir if new check is made.
			if(T in dir_list)
				//Skip steps that are already paths.
			//	if(T in closed_turfs && T != start)
			//		continue
				var/tval = total_list[T]
				var/nval
				//If its pointing at something that is cheaper than it then steal its val
				var/turf/pointing_at = get_step(T, dir_list[T])
				//Dont bother if its just a wall
				if(tval >= 1000)
					if(walk_variables["careful"])
						var/list/double_check_turfs = ReturnAdjacentTurfs(T, TRUE)
						for(var/turf/check in double_check_turfs)
							if(!(check in dir_list))
								continue
							var/flattened_dir = FlattenDiagonal(dir_list[check], get_dir(check,T))
							if(flattened_dir)
								dir_list[check] = flattened_dir
					continue
				//If in total_list with a openf value and is diagonal
				if(pointing_at in total_list && pointing_at.y != T.y && pointing_at.x != T.x)
					nval = total_list[pointing_at]
				if(nval && nval < tval)
					dir_list[T] = new_dir
					openf[T] = nval

			else
				dir_list += T
				dir_list[T] = new_dir
				//Add turf to openf
				if(!(T in openf))
					openf += T
				//Appraise turf
				openf[T] = AppraiseTurf(T,start,end)
				if(openf[T] >= 1000)
					closed_turfs += focus_turf
					closed_turfs[focus_turf] = 1000

		//Add checked focus_turfs to closed_turfs list.
		closed_turfs += focus_turf
		if(focus_turf in openf)
			closed_turfs[focus_turf] = openf[focus_turf]
		closed_turfs[focus_turf] = 0

		//If focus_turf is the end dont worry about checking more.
		if(focus_turf == end)
			break

		//If we have openf turfs to choose from then pick one of those to check.
		if(length(openf))
			var/good_options = openf - closed_turfs
			focus_turf = ReturnLowestValue(good_options)
			//Look i dont care whats behind that wall your not pathing through it. Unless.
			if(good_options[focus_turf] >= 1000)
				break

	var/tag_turf = "[x],[y]"
	var/list/replace_walk_path = FormatDirections(dir_list, start,focus_turf)
	//We are not in the list how can we possibly use this map?
	if(!(tag_turf in replace_walk_path))
		return FALSE
	walk_path = replace_walk_path.Copy()
	return TRUE

/mob/living/simple_animal/hostile/gribble/ribble/proc/FormatDirections(list/dir_list = list(), turf/start, turf/end)
	. = list()
	if(!length(dir_list))
		stack_trace("FormatDirections:NoDirList:[type]")
		return

	if(!start || !end)
		stack_trace("FormatDirections:nostartorend:[type]")
		return

	var/list/return_list = list()
	for(var/turf/floor in dir_list)
		var/tag_turf = "[floor.x],[floor.y]"
		return_list += tag_turf
		return_list[tag_turf] = dir_list[floor]
		if(floor == start)
			return_list[tag_turf] = "dest"

	return return_list

//For dangerous turfs. If a dangerous turf is north of a arrow pointing northeast it will change it to east.
/mob/living/simple_animal/hostile/gribble/ribble/proc/FlattenDiagonal(direct, remove_dir)
	if(direct == NORTHWEST)
		if(remove_dir == NORTH)
			return WEST
		if(remove_dir == WEST)
			return NORTH
	if(direct == NORTHEAST)
		if(remove_dir == NORTH)
			return EAST
		if(remove_dir == EAST)
			return NORTH
	if(direct == SOUTHEAST)
		if(remove_dir == SOUTH)
			return EAST
		if(remove_dir == EAST)
			return SOUTH
	if(direct == SOUTHWEST)
		if(remove_dir == SOUTH)
			return WEST
		if(remove_dir == WEST)
			return SOUTH

/mob/living/simple_animal/hostile/gribble/ribble/proc/CountDist(turf/T, turf/dest)
	if(!T || !dest)
		return 0
	return PYTHAGOREAN(T.x,dest.x,T.y,dest.y) * 10

/mob/living/simple_animal/hostile/gribble/ribble/proc/AppraiseTurf(turf/T, turf/start, turf/end)
	. = 0
	if(T == end)
		return -1
	if(T.density || !istype(T, /turf/open))
		return 10000
	//Hcost
	var/h_cost = CountDist(T,end)
	//Gcost
	var/g_cost = CountDist(T,start)

	. += (h_cost + g_cost)


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
			. += 10
			total_extra += 10
			break

	for(var/obj/machinery/M in O)
		total_check++
		if(total_extra > 50 || total_check >= 20)
			break
		if(M.density)
			if(!istype(M,/obj/machinery/door))
				if(M.resistance_flags & INDESTRUCTIBLE)
					return 10000
				. += 20
				total_extra += 20
				break
			//Mostly because im sick of them ignoring doors.
			. -= 10
			total_extra -= 10

	for(var/obj/effect/turf_fire/F in O)
		total_check++
		if(total_extra > 50 || total_check >= 5)
			break
		if(QDELETED(F))
			continue
		var/fire_resist = 1
		if(FIRE in damage_coeff)
			fire_resist = damage_coeff[FIRE]
		. += 100 * fire_resist
		break

	if(total_extra > 50)
		return

	for(var/mob/living/L in O)
		total_check++
		if(total_check >= 10)
			break
		if(L.density)
			. += 10
			break

/mob/living/simple_animal/hostile/gribble/ribble/proc/ReturnAdjacentTurfs(turf/focus_turf, strict_adjacent = FALSE)
	var/list/return_list = list()
	//Just give me adjacent turfs
	var/fx = focus_turf.x
	var/fy = focus_turf.y
	var/fz = focus_turf.z
	if(strict_adjacent)
		return_list += block(fx - 1,fy,fz,fx + 1,fy,fz) - focus_turf
		return_list += block(fx,fy -1 ,fz,fx,fy + 1,fz) - focus_turf
	else
		return_list += block(fx -1,fy -1,fz,fx +1,fy +1,fz) - focus_turf
	return return_list

#undef PYTHAGOREAN

//---------------------------------------------------
