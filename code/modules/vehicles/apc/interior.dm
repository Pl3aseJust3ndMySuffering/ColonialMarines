// APC interior stuff

//wall

/obj/structure/interior_wall/apc
	name = "\improper APC interior wall"
	icon = 'icons/obj/vehicles/interiors/apc.dmi'
	icon_state = "apc_right_1"

/obj/structure/interior_exit/vehicle/apc
	name = "APC side door"
	icon = 'icons/obj/vehicles/interiors/apc.dmi'
	icon_state = "exit_door"

/obj/structure/interior_exit/vehicle/apc/rear
	name = "APC rear hatch"
	icon_state = "door_rear_center"

/obj/structure/interior_exit/vehicle/apc/rear/left
	icon_state = "door_rear_left"

/obj/structure/interior_exit/vehicle/apc/rear/right
	icon_state = "door_rear_right"

/obj/structure/prop/firing_port_weapon
	name = "M56 FPW handle"
	desc = "A control handle for a modified M56B Smartgun installed on the sides of M577 Armored Personnel Carrier as a Firing Port Weapon. \
	Used by support gunners to cover friendly infantry entering or exiting APC via side doors. \
	Do not be mistaken however, this is not a piece of an actual weapon, but a joystick made in a familiar to marines form."

	icon = 'icons/obj/vehicles/interiors/apc.dmi'
	icon_state = "m56_FPW"

	density = FALSE
	unacidable = TRUE
	unslashable = TRUE
	breakable = FALSE
	indestructible = TRUE
