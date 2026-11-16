/obj/machinery/city_imports
	name = "Imports Vendor"
	desc = "A machine connected to a vast import network. If you need something that isnt in the district, here is where you will find it."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_structures.dmi'
	icon_state = "fish_machine"
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	var/raw_money = 0
	var/screen_one = 0

	var/list/tax_record = list()

	var/list/order_list = list()


/obj/machinery/city_imports/ui_interact(mob/user) //Unsure if this can stand on its own as a structure, later on we may fiddle with that to break out of computer variables. -IP
	. = ..()
	if(!length(order_list))
		update_stock()
	if(isliving(user))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	var/dat
	dat += ImportUI(user)
	var/datum/browser/popup = new(user, "ImportVendor", "ImportVendor", 440, 640)
	popup.set_content(dat)
	popup.open()

/obj/machinery/city_imports/Topic(href, href_list)
	. = ..()
	if(.)
		return .
	if(!ishuman(usr))
		return
	usr.set_machine(src)
	add_fingerprint(usr)
	if(href_list["set_screen_one"])
		var/level = text2num(href_list["set_screen_one"])
		if(!(level < 0 || level > 5) && level != screen_one)
			screen_one = level
			playsound(get_turf(src), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
			updateUsrDialog()
			return TRUE
		return FALSE
	if(href_list["purchase"])
		var/datum/data/extraction_cargo/product_datum = locate(href_list["purchase"]) in order_list
		//The href_list returns the individual number code and only works if we have it in the first column. -IP
		PurchaseTemplate(usr, product_datum)
		playsound(get_turf(src), 'sound/machines/machine_vend.ogg', 10, TRUE)
		updateUsrDialog()
		return TRUE

/obj/machinery/city_imports/proc/ImportUI(mob/user)
	if(screen_one == 0)
		. = ". = ImportUI(); run Scan.exe<br>"
		. = "Welcome valued customer! Do not fear for we have all your needs.<br>"
	. = ProductUI(user)
	//self, topic as text, value of topic, text
	GENERAL_BUTTON(src, "exit",1,"EXIT")

/obj/machinery/city_imports/proc/ProductUI(mob/user)
	var/dat = ""
	var/monies = GetPlayerBalance(user)
	dat = "CARD ACCOUNT BALANCE: [monies]<br>"
	for(var/level = 0 to 5)
		dat += "<A href='byond://?src=[REF(src)];set_screen_one=[level]'>[level == screen_one ? "<b><u>[name_catagory(level)]</u></b>" : "[name_catagory(level)]"]</A>"
	dat += "<br>"
	for(var/datum/data/extraction_cargo/A in order_list)
		if(A.catagory != screen_one)
			continue
		dat += " <A href='byond://?src=[REF(src)];purchase=[REF(A)]'>[A.equipment_name]([A.cost] PE)</A><br>"
	return dat

/obj/machinery/city_imports/proc/PurchaseTemplate(mob/living/user, datum/data/extraction_cargo/product_datum)
	if(!product_datum)
		return FALSE
	if(!ishuman(user))
		to_chat(user, span_warning("You cannot use this machine."))
		return FALSE
	var/template_type = product_datum.equipment_path

	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C)
		to_chat(user, span_warning("You need an ID card to make purchases."))
		return FALSE

	if(!C.registered_account)
		to_chat(user, span_warning("Your ID card has no linked bank account."))
		return FALSE

	var/cost = 0 + product_datum.cost

	var/datum/bank_account/account = C.registered_account
	if(!account.adjust_money(-cost))
		to_chat(user, span_warning("Insufficient funds! You need [cost] Ahn but only have [account.account_balance] Ahn."))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		return FALSE

	// Create the template
	var/obj/item/new_template = new template_type(get_turf(src))
	user.put_in_hands(new_template)

	to_chat(user, span_notice("Purchased [new_template.name] for [cost] Ahn. Remaining balance: [account.account_balance] Ahn."))
	playsound(src, 'sound/effects/cashregister.ogg', 30, TRUE)

	SStgui.update_uis(src)
	return TRUE


/obj/machinery/city_imports/proc/PackageThing(obj/item/O, mob/living/user)
	if(!O)
		return
	if(istype(O, /obj/item/small_delivery))
		return O
	var/obj/item/small_delivery = new(get_turf(src))
	small_delivery.name = "[O] parcel"
	O.forceMove(small_delivery)
	var/size = round(O.w_class)
	small_delivery.name = "[weightclass2text(size)] parcel"
	small_delivery.w_class = size
	size = min(size, 5)
	small_delivery.icon_state = "deliverypackage[size]"
	return small_delivery

/*--------\
|TECHNICAL|
\--------*/

/// Get the player's current Ahn balance
/obj/machinery/city_imports/proc/GetPlayerBalance(mob/living/user)
	if(!ishuman(user))
		return 0

	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C || !C.registered_account)
		return 0

	return C.registered_account.account_balance

/obj/machinery/city_imports/proc/name_catagory(cat) //for each catagory please place the number its defined as -IP
	switch(cat)
		if(0)
			return "Frontpage"
		if(1)
			return "Medical"
		if(2)
			return "Resources"
		if(3)
			return "TBD"
		if(4)
			return "TBD"
		if(5)
			return "TBD"

/*------------\
|PRODUCT STOCK|
\------------*/

/*
*	After researching game economies ive come to
*	some notes on how to price items.
*	The general concensus ive found is to base it
*	on how many paychecks it should take to
*	return their investment, IE 5 missions to
*	afford a package.
*	The Assassination Console currently pays out
*	1k ahn so how many assassinations should it
*	take?
*/
/obj/machinery/city_imports/proc/update_stock()
	QDEL_LIST(order_list)
	order_list = list(
		new /datum/data/extraction_cargo("Bulk Med Package ",		/obj/item/small_delivery/bulk/med,						250,		1) = 1,

		new /datum/data/extraction_cargo("Bulk Burger Patty Pack ",	/obj/item/small_delivery/bulk/burger,					500,		2) = 1,
	)

/*---------\
|BULK ITEMS|
\---------*/
/obj/item/small_delivery/bulk
	var/list/items = list()
	w_class = WEIGHT_CLASS_BULKY

/obj/item/small_delivery/bulk/Initialize()
	. = ..()
	for(var/type in items)
		if(!items[type])
			continue
		var/amt = items[type]
		if(!isnum(amt))
			continue
		for(var/i = 1 to amt)
			new type(src)

/*
*	If the average income of a fixer is 1k
*	then 5 patties being 100 each. Make it
*	a hundred.
*/

/obj/item/small_delivery/bulk/burger
	name = "Bulk Burger Patty Pack"
	items = list(
	/obj/item/food/raw_patty = 5
	)

/obj/item/small_delivery/bulk/med
	name = "Bulk Med Pack"
	items = list(
	/obj/item/stack/medical/suture/emergency = 5
	)
