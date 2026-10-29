/obj/structure/rce_core
	name = "Rcorp Engine Core"
	desc = "A haphazardly repaired engine for a Rcorp expedition train."
	icon_state = "powerpylon"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	max_integrity = 3000

	//Delay in Consume() effect.
	var/input_cooldown = 0
	var/input_delay

	var/fuel = 0
	var/fuel_max = 10000

	var/fuel_value_list = list(
		/obj/item/factoryitem/green = 1,
		/obj/item/factoryitem/red = 1,
		/obj/item/factoryitem/blue = 5,
		/obj/item/factoryitem/purple = 5,
		/obj/item/factoryitem/orange = 10,
		/obj/item/factoryitem/silver = 10
		)

/obj/structure/rce_core/CanAllowThrough(atom/movable/mover, turf/target)
	if(Consume(mover, FACTORY_INPUT_CONVEYOR))
		return TRUE
	return ..()

//If attacked with a item assume we are being fed it as a resource
/obj/structure/rce_core/attackby(obj/item/I, mob/living/user, params)
	if(Consume(I, FACTORY_INPUT_HAND))
		return
	return ..()

//Copy of /obj/machinery/factory_machine InputItem proc
/obj/structure/rce_core/proc/Consume(atom/E, input_method)
	. = TRUE
	if(QDELETED(E))
		return FALSE
	//For staggering the constant flow of material into the machine.
	if(input_delay && input_method != FACTORY_INPUT_HAND)
		if(input_cooldown > world.time)
			return FALSE
		input_cooldown = world.time + input_delay
	fuel_val = fuel_value_list[E.type]
	if(!fuel_val)
		return FALSE
	qdel(E)
	fuel += fuel_val
