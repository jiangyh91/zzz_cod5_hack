#include maps\_anim; 
#include maps\_utility; 
#include common_scripts\utility;
#include maps\_music; 
#include maps\sumpf\_zombiemode_utility; 
#include maps\_busing;
#include maps\_rampage_utility;

#include maps\_rampage_util2;
#include maps\menu_classes;

#using_animtree( "generic_human" ); 

main()
{
////---------------TIMED GAME PLAY SETTINGS (Tom_bmx.win)-----------------////
	level.tom_use_timer = true;
	// if not using menu button set to true...
	level.override_menu_selection = false;

	// set if players spawn on other players of default spawn points.
	level.spectaors_spawn_on_players = false;

	// enables dogs spawning with zombies.
	level.enable_mix_dogs = true;
	// fake rounds between dogs.
	level.fake_rounds_till_dogs = 6;
	// enables dog notification hud // as seen here -- >  http://i49.tinypic.com/2yy5fdj.jpg
	level.dog_hud = true;

	// enables pausing of zombie spwning.
	level.enable_breaks = true;
	// enables notification hud // as seen here -- >  http://i48.tinypic.com/15oez2q.jpg
	level.break_hud = true;
	// how long the break is.
	level.break_timeperiod = 25; // seconds
    // the avg time before a break is valid
	level.avg_time_till_break = 240;// 5 mins
////---------------------------------------////
	precache_shaders();
	precache_models();

	PrecacheItem( "fraggrenade" );
	PrecacheItem( "colt" );

	init_strings();
	init_levelvars();
	init_animscripts();
	init_sounds();
	init_shellshocks();
	init_flags();

	// RAMPAGE - RANKS
	level.rankedMatch = true;
	level.ranks_on = true;

	// RAMPAGE - OTHER VARIABLES
	maps\_rampage_util::rampage_variables();
	maps\_rampage_precache::init_precache();
	maps\_rampage_perk::init_p();

	// the initial spawners
	level.enemy_spawns = getEntArray( "zombie_spawner_init", "targetname" ); 
	SetAILimit( 24 );

	//maps\_destructible_type94truck::init(); 

	level.custom_introscreen = ::zombie_intro_screen; 
	level.reset_clientdvars = ::onPlayerConnect_clientDvars;

	init_fx(); 
	
	maps\_challenges_coop::init();

	// load map defaults
	maps\_load::main();

	level.hudelem_count = 0;
	// Call the other zombiemode scripts
	maps\_zombiemode_net::init();
	maps\sumpf\_zombiemode_weapons_sumpf::init();
	maps\sumpf\_zombiemode_blockers::init();
	maps\sumpf\_zombiemode_spawner::init();
	maps\sumpf\_zombiemode_powerups::init();
	maps\sumpf\_zombiemode_radio::init();	
	maps\sumpf\_zombiemode_perks::init();
	maps\sumpf\_zombiemode_tesla::init();
	maps\sumpf\_zombiemode_dogs::init();

	/#
		maps\sumpf\_zombiemode_devgui::init();
	#/

	init_utility();

	// register a client system...
	maps\_utility::registerClientSys("zombify");

	level thread coop_player_spawn_placement();

	// zombie ai and anim inits
	init_anims(); 

	// Sets up function pointers for animscripts to refer to
	level.playerlaststand_func = ::player_laststand;
	//	level.global_kill_func = maps\_zombiemode_spawner::zombie_death; 
	level.global_damage_func = maps\sumpf\_zombiemode_spawner::zombie_damage; 
	level.global_damage_func_ads = maps\sumpf\_zombiemode_spawner::zombie_damage_ads;
	level.overridePlayerKilled = ::player_killed_override;
	level.overridePlayerDamage = ::player_damage_override;

	// used to a check in last stand for players to become zombies
	level.is_zombie_level = true; 
	level.player_becomes_zombie = ::zombify_player; 

	// so we dont get the uber colt when we're knocked out
	level.laststandpistol = "colt";

	level.round_start_time = 0;

	level thread onPlayerConnect(); 

	init_dvars();
	initZombieLeaderboardData();


	flag_wait( "all_players_connected" ); 
	
	if(!level.override_menu_selection)
	{
	 m = getDvarInt("tom_usetimer");
	 if(m == 1)
	  level.tom_use_timer = true;
	 else if(m == 0)
	  level.tom_use_timer = false;
	}

	if(level.script == "nazi_zombie_asylum" || level.script == "nazi_zombie_factory" || level.script == "nazi_zombie_sumpf")
	{
		maps\sumpf\_zombiemode_achievement::init();
	}
	//thread zombie_difficulty_ramp_up(); 

	// Start the Zombie MODE!
	level waittill( "game_is_ready" );
	setDvar("a_game","1");
	level thread round_start();
	level thread players_playing();

	//chrisp - adding spawning vo 
	level thread spawn_vo();
	
	//add ammo tracker for VO
	level thread track_players_ammo_count();
	
	//level thread prevent_near_origin();

	DisableGrenadeSuicide();

	level.startInvulnerableTime = GetDvarInt( "player_deathInvulnerableTime" );

	// Do a SaveGame, so we can restart properly when we die
	SaveGame( "zombie_start", &"AUTOSAVE_LEVELSTART", "", true );
	
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		players[i].headshots1 = 0;
		players[i].revives1 = 0;
		players[i].downs1 = 0;
		players[i].knives1 = 0;
		players[i].mostheadshots = false;
		players[i].mostrevives = false;
		players[i].hardest2kill = false;
		players[i].mostknives = false;
	}

	// TESTING
	//	wait( 3 );
	//	level thread intermission();
	//	thread testing_spawner_bug();

	if(!IsDefined(level.eggs) )
	{
		level.eggs = 0;
	}
}

onPlayerConnect()
{
	for( ;; )
	{
		level waittill( "connecting", player ); 
		
		player setclientdvar("rampage_whosupport","");
		player setclientdvar("rampage_whosoldier","");
		player setclientdvar("rampage_whoengineer","");
		player setclientdvar("rampage_whomedic","");
		player setclientdvar("rampage_myclass", "");
		player setclientdvar("rampage_showupgradebar", "0");
		player setclientdvar("rampage_showzombiecounter", "1");
		player setclientdvar("r_myability", "");
		player setclientdvar("soldier_allow_berserk", "0");
		player.actual_ability = undefined;
		
		player.berserk_allowed = false;
		
		player.showupgradebar = false;
		player.showzombiecounter = true;
		player.class_shortname = undefined;
		player.repairTrigger = false;
		
		player.new_overkill = getdvar("rampage_newoverkill");
		player.new_overkill_primary = undefined;
		player.my_health = 100;
		player.berserk = false;
		player.is_drinking = 0;
		player.armorvest_up = 0;
		player.bulletdamage_up = 0;
		player.fastreload_up = 0;
		player.longersprint_up = 0;
		player.quickrevive_up = 0;
		player.rof_up = 0;
		player.bulletaccuracy_up = 0;
		player.armorvest_up2 = 0;
		player.fastreload_up2 = 0;
		player.quickrevive_up2 = 0;
		player.rof_up2 = 0;
		player.h_streak = 0;
		player.streak_one = false;
		player.streak_two = false;
		player.streak_three = false;
		player.double_xp = undefined;
		player.was_in_spec = false;
		player.max_health = 100;
		player.revive_on = false;
		player.ammo_on = false;
		player.build_on = false;
		player.old_class = "";
		player.gun_primary = undefined;
		player.gun_secondary = undefined;
		player.inventory = undefined;
		player.grenade_primary = undefined;
		player.grenade_secondary = undefined;
		player.weapon_attachment = undefined;
		player.grenade_count = undefined;
		player.perk1 = undefined;
		player.perk2 = undefined;
		player.perk3 = undefined;
		player.ability = undefined;
		player.time2 = undefined;
		player.time_played = undefined;
		player.show_rank_bar = 1;
		player.is_repairing = false;
		player.myhealthregentime = 0.2;
		player.myblockercost = 1;
		player.rebuild_barrier_reward = 0;
		
		player.entity_num = player GetEntityNumber();

		player thread maps\menu_classes::menu_class_response();
		
		player thread onPlayerSpawned(); 
		player thread onPlayerDisconnect();
		player thread player_revive_monitor();
		
		//player thread watchGrenadeThrow();
		
		player thread maps\_rampage_util2::player_update_time_played();
		
		player.score = level.zombie_vars["zombie_score_start"]; 
		player.score_total = player.score; 
		player.old_score = player.score; 
		
		player.is_zombie = false; 
		player.initialized = false;
		player.zombification_time = 0;
	}
}

/*------------------------------------
chrisp - adding vo to track players ammo
------------------------------------*/
track_players_ammo_count()
{
	self endon("disconnect");
	self endon("death");
	if(!IsDefined (level.player_ammo_low))	
	{
		level.player_ammo_low = 0;
	}	
	if(!IsDefined(level.player_ammo_out))
	{
		level.player_ammo_out = 0;
	}
	while(1)
	{
		players = get_players();
		for(i=0;i<players.size;i++)
		{
	
			weap = players[i] getcurrentweapon();
			//iprintln("current weapon: " + weap);
			//iprintlnbold(weap);
			//Excludes all Perk based 'weapons' so that you don't get low ammo spam.
			if(!isDefined(weap) || weap == "ammo_bag" || weap == "none" || weap == "zombie_perk_bottle_doubletap" || weap == "zombie_perk_bottle_jugg" || weap == "zombie_perk_bottle_revive" || weap == "zombie_perk_bottle_sleight" || weap == "mine_bouncing_betty" || weap == "syrette")
			{
				continue;
			}
			//iprintln("checking ammo for " + weap);
			if ( players[i] GetAmmoCount( weap ) > 5)
			{
				continue;
			}		
			if ( players[i] maps\_laststand::player_is_in_laststand() )
			{				
				continue;
			}
			else if (players[i] GetAmmoCount( weap ) < 5 && players[i] GetAmmoCount( weap ) > 0)
			{
				if (level.player_ammo_low == 0)
				{
					level.player_ammo_low = 1;
					players[i] thread add_low_ammo_dialog();		
					players[i] thread ammo_dialog_timer();
					level waittill("send_dialog_reminder");
					level.player_ammo_low = 0;
				}
	
			}
			else if (players[i] GetAmmoCount( weap ) == 0)
			{	
				if(!isDefined(weap) || weap == "none")
				{
					continue;	
				}				
				level.player_ammo_out = 1;
				players[i] thread add_no_ammo_dialog();
				//put in this wait to keep the game from spamming about being low on ammo.
				wait(20);
				level.player_ammo_out = 0;												
			}
			else
			{
				continue;
			}
		}
		wait(.5);
	}	
}
ammo_dialog_timer()
{
	level endon ("ammo_out");
	while(1)
	{
		wait(20);
		level notify ("send_dialog_reminder");	
		
	}	
	
}
add_low_ammo_dialog()
{
	index = maps\sumpf\_zombiemode_weapons_sumpf::get_player_index(self);	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_ammo_low))
	{
		num_variants = maps\sumpf\_zombiemode_spawner::get_number_variants(player_index + "vox_ammo_low");
		self.vox_ammo_low = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_ammo_low[self.vox_ammo_low.size] = "vox_ammo_low_" + i;	
		}
		self.vox_ammo_low_available = self.vox_ammo_low;		
	}	
	sound_to_play = random(self.vox_ammo_low_available);
	
	self.vox_ammo_low_available = array_remove(self.vox_ammo_low_available,sound_to_play);
	
	if (self.vox_ammo_low_available.size < 1 )
	{
		self.vox_ammo_low_available = self.vox_ammo_low;
	}
			
	self maps\sumpf\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, 0.25);	
	
	
	
}
add_no_ammo_dialog()
{
	index = maps\sumpf\_zombiemode_weapons_sumpf::get_player_index(self);	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_ammo_out))
	{
		num_variants = maps\sumpf\_zombiemode_spawner::get_number_variants(player_index + "vox_ammo_out");
		self.vox_ammo_out = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_ammo_out[self.vox_ammo_out.size] = "vox_ammo_out_" + i;	
		}
		self.vox_ammo_out_available = self.vox_ammo_out;		
	}	
	sound_to_play = random(self.vox_ammo_out_available);
	
	self.vox_ammo_out_available = array_remove(self.vox_ammo_out_available,sound_to_play);
	
	if (self.vox_ammo_out_available.size < 1 )
	{
		self.vox_ammo_out_available = self.vox_ammo_out;
	}
			
	self maps\sumpf\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, 0.25);	
	
	
	
}
/*------------------------------------
audio plays when more than 1 player connects
------------------------------------*/
spawn_vo()
{
	//not sure if we need this
	wait(1);
	
	players = getplayers();
	
	//just pick a random player for now and play some vo 
	if(players.size > 1)
	{
		player = random(players);
		index = maps\sumpf\_zombiemode_weapons_sumpf::get_player_index(player);
		player thread spawn_vo_player(index,players.size);
	}

}

spawn_vo_player(index,num)
{
	sound = "plr_" + index + "_vox_" + num +"play";
	self playsound(sound, "sound_done");			
	self waittill("sound_done");
}

testing_spawner_bug()
{
	wait( 0.1 );
	level.round_number = 7;

	spawners = [];
	spawners[0] = GetEnt( "testy", "targetname" );
	while( 1 )
	{
		wait( 1 );
		level.enemy_spawns = spawners;
	}
}

precache_shaders()
{
}

precache_models()
{
	precachemodel( "char_ger_honorgd_zomb_behead" ); 
	precachemodel( "char_ger_zombieeye" ); 
	PrecacheModel( "tag_origin" );
}

init_shellshocks()
{
	level.player_killed_shellshock = "zombie_death";
	PrecacheShellshock( level.player_killed_shellshock );
}

init_strings()
{
	PrecacheString( &"ZOMBIE_WEAPONCOSTAMMO" );
	PrecacheString( &"ZOMBIE_ROUND" );
	PrecacheString( &"SCRIPT_PLUS" );
	PrecacheString( &"ZOMBIE_GAME_OVER" );
	PrecacheString( &"ZOMBIE_SURVIVED_ROUND" );
	PrecacheString( &"ZOMBIE_SURVIVED_ROUNDS" );

	add_zombie_hint( "undefined", &"ZOMBIE_UNDEFINED" );

	// Random Treasure Chest
	add_zombie_hint( "default_treasure_chest_950", &"ZOMBIE_RANDOM_WEAPON_950" );

	// Barrier Pieces
	add_zombie_hint( "default_buy_barrier_piece_10", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_10" );
	add_zombie_hint( "default_buy_barrier_piece_20", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_20" );
	add_zombie_hint( "default_buy_barrier_piece_50", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_50" );
	add_zombie_hint( "default_buy_barrier_piece_100", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_100" );

	// REWARD Barrier Pieces
	add_zombie_hint( "default_reward_barrier_piece", &"ZOMBIE_BUTTON_REWARD_BARRIER" );
	add_zombie_hint( "default_reward_barrier_piece_10", &"ZOMBIE_BUTTON_REWARD_BARRIER_10" );
	add_zombie_hint( "default_reward_barrier_piece_20", &"ZOMBIE_BUTTON_REWARD_BARRIER_20" );
	add_zombie_hint( "default_reward_barrier_piece_30", &"ZOMBIE_BUTTON_REWARD_BARRIER_30" );
	add_zombie_hint( "default_reward_barrier_piece_40", &"ZOMBIE_BUTTON_REWARD_BARRIER_40" );
	add_zombie_hint( "default_reward_barrier_piece_50", &"ZOMBIE_BUTTON_REWARD_BARRIER_50" );

	// Debris
	add_zombie_hint( "default_buy_debris_100", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_100" );
	add_zombie_hint( "default_buy_debris_200", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_200" );
	add_zombie_hint( "default_buy_debris_250", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_250" );
	add_zombie_hint( "default_buy_debris_500", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_500" );
	add_zombie_hint( "default_buy_debris_750", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_750" );
	add_zombie_hint( "default_buy_debris_1000", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1000" );
	add_zombie_hint( "default_buy_debris_1250", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1250" );
	add_zombie_hint( "default_buy_debris_1500", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1500" );
	add_zombie_hint( "default_buy_debris_1750", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1750" );
	add_zombie_hint( "default_buy_debris_2000", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_2000" );

	// Doors
	add_zombie_hint( "default_buy_door_100", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_100" );
	add_zombie_hint( "default_buy_door_200", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_200" );
	add_zombie_hint( "default_buy_door_250", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_250" );
	add_zombie_hint( "default_buy_door_500", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_500" );
	add_zombie_hint( "default_buy_door_750", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_750" );
	add_zombie_hint( "default_buy_door_1000", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1000" );
	add_zombie_hint( "default_buy_door_1250", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1250" );
	add_zombie_hint( "default_buy_door_1500", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1500" );
	add_zombie_hint( "default_buy_door_1750", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1750" );
	add_zombie_hint( "default_buy_door_2000", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_2000" );

	// Areas
	add_zombie_hint( "default_buy_area_100", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_100" );
	add_zombie_hint( "default_buy_area_200", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_200" );
	add_zombie_hint( "default_buy_area_250", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_250" );
	add_zombie_hint( "default_buy_area_500", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_500" );
	add_zombie_hint( "default_buy_area_750", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_750" );
	add_zombie_hint( "default_buy_area_1000", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1000" );
	add_zombie_hint( "default_buy_area_1250", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1250" );
	add_zombie_hint( "default_buy_area_1500", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1500" );
	add_zombie_hint( "default_buy_area_1750", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1750" );
	add_zombie_hint( "default_buy_area_2000", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_2000" );
}

init_sounds()
{
	add_sound( "end_of_round", "round_over" );
	add_sound( "end_of_game", "mx_game_over" ); //Had to remove this and add a music state switch so that we can add other musical elements.
	add_sound( "chalk_one_up", "chalk" );
	add_sound( "purchase", "cha_ching" );
	add_sound( "no_purchase", "no_cha_ching" );

	// Zombification
	// TODO need to vary these up
	add_sound( "playerzombie_usebutton_sound", "attack_vocals" );
	add_sound( "playerzombie_attackbutton_sound", "attack_vocals" );
	add_sound( "playerzombie_adsbutton_sound", "attack_vocals" );

	// Head gib
	add_sound( "zombie_head_gib", "zombie_head_gib" );

	// Blockers
	add_sound( "rebuild_barrier_piece", "repair_boards" );
	add_sound( "rebuild_barrier_hover", "boards_float" );
	add_sound( "debris_hover_loop", "couch_loop" );
	add_sound( "break_barrier_piece", "break_boards" );
	add_sound("blocker_end_move", "board_slam");
	add_sound( "barrier_rebuild_slam", "board_slam" );

	// Doors
	add_sound( "door_slide_open", "door_slide_open" );
	add_sound( "door_rotate_open", "door_slide_open" );

	// Debris
	add_sound( "debris_move", "weap_wall" );

	// Random Weapon Chest
	add_sound( "open_chest", "lid_open" );
	add_sound( "music_chest", "music_box" );
	add_sound( "close_chest", "lid_close" );

	// Weapons on walls
	add_sound( "weapon_show", "weap_wall" );

}

init_dvars()
{
	level.cheating2 = 0;
	level.zombiemode = true;

	//coder mod: tkeegan - new code dvar
	setSavedDvar( "zombiemode", "1" );
	SetDvar( "ui_gametype", "zom" );	
	setSavedDvar( "fire_world_damage", "0" );	
	setSavedDvar( "fire_world_damage_rate", "0" );	
	setSavedDvar( "fire_world_damage_duration", "0" );	

	if( GetDvar( "zombie_debug" ) == "" )
	{
		SetDvar( "zombie_debug", "0" );
	}

	if( GetDvar( "zombie_cheat" ) == "" )
	{
		SetDvar( "zombie_cheat", "0" );
	}
	
	if(getdvar("magic_chest_movable") == "")
	{
		SetDvar( "magic_chest_movable", "1" );
	}

	if(getdvar("magic_box_explore_only") == "")
	{
		SetDvar( "magic_box_explore_only", "1" );
	}
	
	//setDvar("god","0");
	setDvar("sf_use_ignoreammo","0");
	setDvar("player_sustainammo","0");
	setDvar("sv_cheats","0");
	setDvar("noclip","0");
	setDvar("ufo","0");
	//setDvar("give","");
	
	thread cheat_hud();
	thread reset_commands();
}

reset_others()
{
	self endon("disconnect");
	while(1)
	{
		wait(0.05);
		self setclientdvars("g_gravity",800,
		"phys_gravity",-800,
		"arcademode",0,
		"revive_trigger_radius",40,
		"player_reviveTriggerRadius",64,
		"player_meleedamagemultiplier",0.4,
		"player_laststandbleedouttime",30,
		"pllayer_meleerange",64,
		"player_clipsizemultiplier",1,
		"g_deathdelay",4000,
		"perk_overheatreduction",0.7);
	}
}

reset_commands()
{
	players = get_players();
	while(1)
	{
		wait(0.05);
		setDvar("sf_use_ignoreammo","0");
		setDvar("player_sustainammo","0");
		setDvar("revive_trigger_radius","40");
		setDvar("arcademode","0");
		setDvar("player_reviveTriggerRadius","64");
		setDvar("g_gravity","800");
		setDvar("phys_gravity","-800");
		setDvar("player_meleedamagemultiplier","0.4");
		setDvar("player_laststandbleedouttime","30");
		setDvar("player_meleerange","64");
		setDvar("player_clipsizemultiplier","1");
		setDvar("g_deathdelay","4000");
		setDvar("perk_overheatreduction","0.7");
	}
}

initZombieLeaderboardData()
{
	// Initializing Leaderboard Stat Variables
	level.zombieLeaderboardStatVariable["nazi_zombie_prototype"]["highestwave"] = "nz_prototype_highestwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_prototype"]["timeinwave"] = "nz_prototype_timeinwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_prototype"]["totalpoints"] = "nz_prototype_totalpoints";

	level.zombieLeaderboardStatVariable["nazi_zombie_asylum"]["highestwave"] = "nz_asylum_highestwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_asylum"]["timeinwave"] = "nz_asylum_timeinwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_asylum"]["totalpoints"] = "nz_asylum_totalpoints";

	level.zombieLeaderboardStatVariable["nazi_zombie_sumpf"]["highestwave"] = "nz_sumpf_highestwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_sumpf"]["timeinwave"] = "nz_sumpf_timeinwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_sumpf"]["totalpoints"] = "nz_sumpf_totalpoints";

	// Initializing Leaderboard Number
	level.zombieLeaderboardNumber["nazi_zombie_prototype"]["waves"] = 13;
	level.zombieLeaderboardNumber["nazi_zombie_prototype"]["points"] = 14;

	level.zombieLeaderboardNumber["nazi_zombie_asylum"]["waves"] = 15;
	level.zombieLeaderboardNumber["nazi_zombie_asylum"]["points"] = 16;

	level.zombieLeaderboardNumber["nazi_zombie_sumpf"]["waves"] = 17;
	level.zombieLeaderboardNumber["nazi_zombie_sumpf"]["points"] = 18;
}

init_flags()
{
	flag_init("spawn_point_override");
}

init_fx()
{
	level._effect["wood_chunk_destory"]	 	= loadfx( "impacts/large_woodhit" );

	level._effect["edge_fog"]			 	= LoadFx( "env/smoke/fx_fog_zombie_amb" ); 
	level._effect["chest_light"]		 	= LoadFx( "env/light/fx_ray_sun_sm_short" ); 

	level._effect["eye_glow"]			 	= LoadFx( "misc/fx_zombie_eye_single" ); 

	level._effect["zombie_grain"]			= LoadFx( "misc/fx_zombie_grain_cloud" );

	level._effect["headshot"] 				= LoadFX( "impacts/flesh_hit_head_fatal_lg_exit" );
	level._effect["headshot_nochunks"] 		= LoadFX( "misc/fx_zombie_bloodsplat" );
	level._effect["bloodspurt"] 			= LoadFX( "misc/fx_zombie_bloodspurt" );
	level._effect["tesla_head_light"]		= Loadfx( "maps/zombie/fx_zombie_tesla_neck_spurt");

	level._effect["rise_burst_water"]		= LoadFx("maps/zombie/fx_zombie_body_wtr_burst");
	level._effect["rise_billow_water"]	= LoadFx("maps/zombie/fx_zombie_body_wtr_billowing");
	level._effect["rise_dust_water"]		= LoadFx("maps/zombie/fx_zombie_body_wtr_falling");

	// Flamethrower
	level._effect["character_fire_pain_sm"]              		= loadfx( "env/fire/fx_fire_player_sm_1sec" );
	level._effect["character_fire_death_sm"]             		= loadfx( "env/fire/fx_fire_player_md" );
	level._effect["character_fire_death_torso"] 				= loadfx( "env/fire/fx_fire_player_torso" );
}

// zombie specific anims
init_anims()
{
	// deaths
	level.scr_anim["zombie"]["death1"] 	= %ai_zombie_death_v1;
	level.scr_anim["zombie"]["death2"] 	= %ai_zombie_death_v2;
	level.scr_anim["zombie"]["death3"] 	= %ai_zombie_crawl_death_v1;
	level.scr_anim["zombie"]["death4"] 	= %ai_zombie_crawl_death_v2;

	// run cycles
	
	level.scr_anim["zombie"]["walk1"] 	= %ai_zombie_walk_v1;
	level.scr_anim["zombie"]["walk2"] 	= %ai_zombie_walk_v2;
	level.scr_anim["zombie"]["walk3"] 	= %ai_zombie_walk_v3;
	level.scr_anim["zombie"]["walk4"] 	= %ai_zombie_walk_v4;

	level.scr_anim["zombie"]["run1"] 	= %ai_zombie_walk_fast_v1;
	level.scr_anim["zombie"]["run2"] 	= %ai_zombie_walk_fast_v2;
	level.scr_anim["zombie"]["run3"] 	= %ai_zombie_walk_fast_v3;
	level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v2;
	level.scr_anim["zombie"]["run5"] 	= %ai_zombie_run_v4;
	level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v3;
	//level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v1;
	//level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v4;

	level.scr_anim["zombie"]["sprint1"] = %ai_zombie_sprint_v1;
	level.scr_anim["zombie"]["sprint2"] = %ai_zombie_sprint_v2;
	level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v1;
	level.scr_anim["zombie"]["sprint4"] = %ai_zombie_sprint_v2;
	//level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v3;
	//level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v4;
	//level.scr_anim["zombie"]["sprint4"] = %ai_zombie_sprint_v5;

	// run cycles in prone
	level.scr_anim["zombie"]["crawl1"] 	= %ai_zombie_crawl;
	level.scr_anim["zombie"]["crawl2"] 	= %ai_zombie_crawl_v1;
	level.scr_anim["zombie"]["crawl3"] 	= %ai_zombie_crawl_v2;
	level.scr_anim["zombie"]["crawl4"] 	= %ai_zombie_crawl_v3;
	level.scr_anim["zombie"]["crawl5"] 	= %ai_zombie_crawl_v4;
	level.scr_anim["zombie"]["crawl6"] 	= %ai_zombie_crawl_v5;
	level.scr_anim["zombie"]["crawl_hand_1"] = %ai_zombie_walk_on_hands_a;
	level.scr_anim["zombie"]["crawl_hand_2"] = %ai_zombie_walk_on_hands_b;



	
	level.scr_anim["zombie"]["crawl_sprint1"] 	= %ai_zombie_crawl_sprint;
	level.scr_anim["zombie"]["crawl_sprint2"] 	= %ai_zombie_crawl_sprint_1;
	level.scr_anim["zombie"]["crawl_sprint3"] 	= %ai_zombie_crawl_sprint_2;

	if( !isDefined( level._zombie_melee ) )
	{
		level._zombie_melee = [];
	}
	if( !isDefined( level._zombie_walk_melee ) )
	{
		level._zombie_walk_melee = [];
	}
	if( !isDefined( level._zombie_run_melee ) )
	{
		level._zombie_run_melee = [];
	}

	level._zombie_melee["zombie"] = [];
	level._zombie_walk_melee["zombie"] = [];
	level._zombie_run_melee["zombie"] = [];

	level._zombie_melee["zombie"][0] 				= %ai_zombie_attack_forward_v1; 
	level._zombie_melee["zombie"][1] 				= %ai_zombie_attack_forward_v2; 
	level._zombie_melee["zombie"][2] 				= %ai_zombie_attack_v1; 
	level._zombie_melee["zombie"][3] 				= %ai_zombie_attack_v2;	
	level._zombie_melee["zombie"][4]				= %ai_zombie_attack_v1;
	level._zombie_melee["zombie"][5]				= %ai_zombie_attack_v4;
	level._zombie_melee["zombie"][6]				= %ai_zombie_attack_v6;	
	level._zombie_run_melee["zombie"][0]				=	%ai_zombie_run_attack_v1;
	level._zombie_run_melee["zombie"][1]				=	%ai_zombie_run_attack_v2;
	level._zombie_run_melee["zombie"][2]				=	%ai_zombie_run_attack_v3;
	level.scr_anim["zombie"]["walk5"] 	= %ai_zombie_walk_v6;
	level.scr_anim["zombie"]["walk6"] 	= %ai_zombie_walk_v7;
	level.scr_anim["zombie"]["walk7"] 	= %ai_zombie_walk_v8;
	level.scr_anim["zombie"]["walk8"] 	= %ai_zombie_walk_v9;

	if( isDefined( level.zombie_anim_override ) )
	{
		[[ level.zombie_anim_override ]]();
	}

	level._zombie_walk_melee["zombie"][0]			= %ai_zombie_walk_attack_v1;
	level._zombie_walk_melee["zombie"][1]			= %ai_zombie_walk_attack_v2;
	level._zombie_walk_melee["zombie"][2]			= %ai_zombie_walk_attack_v3;
	level._zombie_walk_melee["zombie"][3]			= %ai_zombie_walk_attack_v4;

	// melee in crawl
	if( !isDefined( level._zombie_melee_crawl ) )
	{
		level._zombie_melee_crawl = [];
	}
	level._zombie_melee_crawl["zombie"] = [];
	level._zombie_melee_crawl["zombie"][0] 		= %ai_zombie_attack_crawl; 
	level._zombie_melee_crawl["zombie"][1] 		= %ai_zombie_attack_crawl_lunge;

	if( !isDefined( level._zombie_stumpy_melee ) )
	{
		level._zombie_stumpy_melee = [];
	}
	level._zombie_stumpy_melee["zombie"] = [];
	level._zombie_stumpy_melee["zombie"][0] = %ai_zombie_walk_on_hands_shot_a;
	level._zombie_stumpy_melee["zombie"][1] = %ai_zombie_walk_on_hands_shot_b;
	//level._zombie_melee_crawl["zombie"][2]		= %ai_zombie_crawl_attack_A;

	// tesla deaths
	if( !isDefined( level._zombie_tesla_death ) )
	{
		level._zombie_tesla_death = [];
	}
	level._zombie_tesla_death["zombie"] = [];
	level._zombie_tesla_death["zombie"][0] = %ai_zombie_tesla_death_a;
	level._zombie_tesla_death["zombie"][1] = %ai_zombie_tesla_death_b;
	level._zombie_tesla_death["zombie"][2] = %ai_zombie_tesla_death_c;
	level._zombie_tesla_death["zombie"][3] = %ai_zombie_tesla_death_d;
	level._zombie_tesla_death["zombie"][4] = %ai_zombie_tesla_death_e;

	if( !isDefined( level._zombie_tesla_crawl_death ) )
	{
		level._zombie_tesla_crawl_death = [];
	}
	level._zombie_tesla_crawl_death["zombie"] = [];
	level._zombie_tesla_crawl_death["zombie"][0] = %ai_zombie_tesla_crawl_death_a;
	level._zombie_tesla_crawl_death["zombie"][1] = %ai_zombie_tesla_crawl_death_b;

	if( !isDefined( level._zombie_deaths ) )
	{
		level._zombie_deaths = [];
	}
	level._zombie_deaths["zombie"] = [];
	level._zombie_deaths["zombie"][0] = %ch_dazed_a_death;
	level._zombie_deaths["zombie"][1] = %ch_dazed_b_death;
	level._zombie_deaths["zombie"][2] = %ch_dazed_c_death;
	level._zombie_deaths["zombie"][3] = %ch_dazed_d_death;

	// set up the arrays
	level._zombie_rise_anims = [];

	//level._zombie_rise_anims[1]["walk"][0]		= %ai_zombie_traverse_ground_v1_crawl;
	level._zombie_rise_anims[1]["walk"][0]		= %ai_zombie_traverse_ground_v1_walk;

	//level._zombie_rise_anims[1]["run"][0]		= %ai_zombie_traverse_ground_v1_crawlfast;
	level._zombie_rise_anims[1]["run"][0]		= %ai_zombie_traverse_ground_v1_run;

	level._zombie_rise_anims[1]["sprint"][0]	= %ai_zombie_traverse_ground_climbout_fast;

	//level._zombie_rise_anims[2]["walk"][0]		= %ai_zombie_traverse_ground_v2_walk;	//!broken
	level._zombie_rise_anims[2]["walk"][0]		= %ai_zombie_traverse_ground_v2_walk_altA;
	//level._zombie_rise_anims[2]["walk"][2]		= %ai_zombie_traverse_ground_v2_walk_altB;//!broken

	// ground crawl death
	level._zombie_rise_death_anims = [];

	level._zombie_rise_death_anims[1]["in"][0]		= %ai_zombie_traverse_ground_v1_deathinside;
	level._zombie_rise_death_anims[1]["in"][1]		= %ai_zombie_traverse_ground_v1_deathinside_alt;

	level._zombie_rise_death_anims[1]["out"][0]		= %ai_zombie_traverse_ground_v1_deathoutside;
	level._zombie_rise_death_anims[1]["out"][1]		= %ai_zombie_traverse_ground_v1_deathoutside_alt;

	level._zombie_rise_death_anims[2]["in"][0]		= %ai_zombie_traverse_ground_v2_death_low;
	level._zombie_rise_death_anims[2]["in"][1]		= %ai_zombie_traverse_ground_v2_death_low_alt;

	level._zombie_rise_death_anims[2]["out"][0]		= %ai_zombie_traverse_ground_v2_death_high;
	level._zombie_rise_death_anims[2]["out"][1]		= %ai_zombie_traverse_ground_v2_death_high_alt;
	
	if( !isDefined( level._zombie_run_taunt ) )
	{
		level._zombie_run_taunt = [];
	}
	if( !isDefined( level._zombie_board_taunt ) )
	{
		level._zombie_board_taunt = [];
	}
	level._zombie_run_taunt["zombie"] = [];
	level._zombie_board_taunt["zombie"] = [];
	
	level._zombie_board_taunt["zombie"][0] = %ai_zombie_taunts_4;
	level._zombie_board_taunt["zombie"][1] = %ai_zombie_taunts_7;
	level._zombie_board_taunt["zombie"][2] = %ai_zombie_taunts_9;
	level._zombie_board_taunt["zombie"][3] = %ai_zombie_taunts_5b;
	level._zombie_board_taunt["zombie"][4] = %ai_zombie_taunts_5c;
	level._zombie_board_taunt["zombie"][5] = %ai_zombie_taunts_5d;
	level._zombie_board_taunt["zombie"][6] = %ai_zombie_taunts_5e;
	level._zombie_board_taunt["zombie"][7] = %ai_zombie_taunts_5f;
}

// Initialize any animscript related variables
init_animscripts()
{
	// Setup the animscripts, then override them (we call this just incase an AI has not yet spawned)
	animscripts\init::firstInit();

	anim.idleAnimArray		["stand"] = [];
	anim.idleAnimWeights	["stand"] = [];
	anim.idleAnimArray		["stand"][0][0] 	= %ai_zombie_idle_v1_delta;
	anim.idleAnimWeights	["stand"][0][0] 	= 10;

	anim.idleAnimArray		["crouch"] = [];
	anim.idleAnimWeights	["crouch"] = [];	
	anim.idleAnimArray		["crouch"][0][0] 	= %ai_zombie_idle_crawl_delta;
	anim.idleAnimWeights	["crouch"][0][0] 	= 10;
}

// Handles the intro screen
zombie_intro_screen( string1, string2, string3, string4, string5 )
{
	flag_wait( "all_players_connected" );

	wait( 1 );

	//TUEY Set music state to Splash Screencompass
	setmusicstate( "SPLASH_SCREEN" );
	wait (0.2);
	//TUEY Set music state to WAVE_1
	//	setmusicstate("WAVE_1");
}

players_playing()
{
	// initialize level.players_playing
	players = get_players();
	level.players_playing = players.size;

	wait( 20 );

	players = get_players();
	level.players_playing = players.size;
}

//
// NETWORK SECTION ====================================================================== //
//

watchGrenadeThrow()
{
	self endon( "disconnect" ); 
	self endon( "death" );

	while(1)
	{
		self waittill("grenade_fire", grenade);

		if(isdefined(grenade))
		{
			if(self maps\_laststand::player_is_in_laststand())
			{
				grenade delete();
			}
		}
	}
}

player_revive_monitor()
{
	self endon( "disconnect" ); 

	while (1)
	{
		self waittill( "player_revived", reviver );	

		if ( IsDefined(reviver) )
		{
			points = self.score_lost_when_downed;
			if ( points > 300 )
			{
				points = 300;
			}
			reviver maps\_zombiemode_score::add_to_player_score( points );
			self.score_lost_when_downed = 0;
		}
	}
}

onPlayerConnect_clientDvars()
{
	self SetClientDvars( "cg_deadChatWithDead", "1",
		"cg_deadChatWithTeam", "1",
		"cg_deadHearTeamLiving", "1",
		"cg_deadHearAllLiving", "1",
		"cg_everyoneHearsEveryone", "1",
		"compass", "0",
		"hud_showStance", "0",
		"cg_thirdPerson", "0",
		"cg_fov", "65",
		"cg_thirdPersonAngle", "0",
		"ammoCounterHide", "0",
		"miniscoreboardhide", "0",
		"ui_hud_hardcore", "0",
		"support_locked", "0",
		"soldier_locked", "0",
		"engineer_locked", "0",
		"medic_locked", "0",
		"perk_weapRateMultiplier", "0.75",
		"perk_weapReloadMultiplier", "0.5",
		"perk_weapSpreadMultiplier", "0.65",
		"perk_sprintMultiplier", "0.65",
		"g_speed", "190",
		"a_ready", "0");
		
	self setClientDvar("show_rank_bar","1");
	self SetDepthOfField( 0, 0, 512, 4000, 4, 0 );
}

onPlayerDisconnect()
{
	self waittill( "disconnect" ); 
	self remove_from_spectate_list();
	set_clientdvars_2(self.class_picked);
}

////// Cosalcea
CosalceaWatcher30cal()
{
	self.cleanammofirst = false;

	for( ;; )
	{

		self.has_weapon_30cal = self HasWeapon("30cal_bipod");
		self.current_weapon_30cal = self getCurrentWeapon();
		self.has_ammostock_30cal = self GetWeaponAmmoStock("30cal_bipod");

		if (self.current_weapon_30cal == "30cal_bipod_prone")
		{
			self SetStance("prone");
			self allowstand(false);
			self allowcrouch(false);
		}
		else
		{
			self allowstand(true);
			self allowcrouch(true);
		}	

		if (self.has_weapon_30cal == true && self.current_weapon_30cal != "30cal_bipod_prone" && self.cleanammofirst == false)
		{
			self SetWeaponAmmoClip( "30cal_bipod_prone", 0 );
			self SetWeaponAmmoStock( "30cal_bipod_prone", 150 );
			self.cleanammofirst = true;
		}

		if (self.has_weapon_30cal == true && self.current_weapon_30cal != "30cal_bipod_prone" && self.cleanammofirst == true)
		{
			if(self.has_ammostock_30cal >= 175)
			{
				self SetWeaponAmmoClip( "30cal_bipod_prone", 0 );
				self SetWeaponAmmoStock( "30cal_bipod_prone", 175 );
			}			
		}

		if (self.has_weapon_30cal == false)
		{
			self.cleanammofirst = false;
		}

	wait 1;
	}	
}
//////

onPlayerSpawned()
{
	self endon( "disconnect" ); 

	for( ;; )
	{
		self waittill( "spawned_player" ); 

		////// Cosalcea
		self thread CosalceaWatcher30cal();
		//////
	
		// Added by Rampage - class selection
		self.ignoreme = true;
		self openMenu(game["classmenu"]);
		
		self thread maps\_rampage_util2::rank_progress_bar();
		
		self thread reset_others();

		self SetClientDvars( "cg_thirdPerson", "0",
			"cg_fov", "65",
			"cg_thirdPersonAngle", "0" );

		self SetDepthOfField( 0, 0, 512, 4000, 4, 0 );

		self add_to_spectate_list();

		if( isdefined( self.initialized ) )
		{
			if( self.initialized == false )
			{
				self.initialized = true; 
				//				self maps\_zombiemode_score::create_player_score_hud(); 

				// set the initial score on the hud		
				self maps\_zombiemode_score::set_player_score_hud( true ); 
				self thread player_zombie_breadcrumb();

				//Init stat tracking variables
				self.stats["kills"] = 0;
				self.stats["score"] = 0;
				self.stats["downs"] = 0;
				self.stats["revives"] = 0;
				self.stats["perks"] = 0;
				self.stats["headshots"] = 0;
				self.stats["zombie_gibs"] = 0;
			}
		}
		
		if(!isdefined(self.hud_rankscroreupdate))
		{
			self.hud_rankscroreupdate = NewScoreHudElem(self);
			self.hud_rankscroreupdate.horzAlign = "left";
			self.hud_rankscroreupdate.vertAlign = "bottom";
			self.hud_rankscroreupdate.alignX = "left";
			self.hud_rankscroreupdate.alignY = "bottom";
	 		self.hud_rankscroreupdate.x = 2;
			self.hud_rankscroreupdate.y = -60;
			self.hud_rankscroreupdate.font = "default";
			self.hud_rankscroreupdate.fontscale = 2.0;
			self.hud_rankscroreupdate.archived = false;
			self.hud_rankscroreupdate.color = (0.5,0.5,0.5);
			self.hud_rankscroreupdate.alpha = 0;
			self.hud_rankscroreupdate fontPulseInit();
		}
	}
}

player_laststand()
{
	self maps\_zombiemode_score::player_downed_penalty();

	if( IsDefined( self.intermission ) && self.intermission )
	{
		maps\_challenges_coop::doMissionCallback( "playerDied", self );

		level waittill( "forever" );
	}
}

spawnSpectator()
{
	self endon( "disconnect" ); 
	self endon( "spawned_spectator" ); 
	self notify( "spawned" ); 
	self notify( "end_respawn" );
	self notify( "p_in_ls" );

	if( level.intermission )
	{
		return;
	}

	if( IsDefined( level.no_spectator ) && level.no_spectator )
	{
		wait( 3 );
		ExitLevel();
	}

	// The check_for_level_end looks for this
	self.is_zombie = true;

	// Remove all reviving abilities
	self notify ( "zombified" );

	if( IsDefined( self.revivetrigger ) )
	{
		self.revivetrigger delete();
		self.revivetrigger = undefined;
	}

	self.zombification_time = getTime(); //set time when player died

	resetTimeout(); 

	// Stop shellshock and rumble
	self StopShellshock(); 
	self StopRumble( "damage_heavy" ); 

	self.sessionstate = "spectator"; 
	self.spectatorclient = -1;

	self remove_from_spectate_list();

	self.maxhealth = self.health;
	self.shellshocked = false; 
	self.inWater = false; 
	self.friendlydamage = undefined; 
	self.hasSpawned = true; 
	self.spawnTime = getTime(); 
	self.afk = false; 
	self.was_in_spec = true;

	if(level.tom_use_timer)
	{
		self thread tom_respawn_counter();
	}
	println( "*************************Zombie Spectator***" );
	self detachAll();

	self setSpectatePermissions( true );
	self thread spectator_thread();

	self Spawn( self.origin, self.angles );
	self notify( "spawned_spectator" );
}

setSpectatePermissions( isOn )
{
	self AllowSpectateTeam( "allies", isOn );
	self AllowSpectateTeam( "axis", false );
	self AllowSpectateTeam( "freelook", false );
	self AllowSpectateTeam( "none", false );	
}

spectator_thread()
{
	self endon( "disconnect" ); 
	self endon( "spawned_player" );

	if( IsSplitScreen() )
	{
		last_alive = undefined;
		players = get_players();

		for( i = 0; i < players.size; i++ )
		{
			if( !players[i].is_zombie )
			{
				last_alive = players[i];
			}
		}

		share_screen( last_alive, true );

		return;
	}

	self thread spectator_toggle_3rd_person();
}

spectator_toggle_3rd_person()
{
	self endon( "disconnect" ); 
	self endon( "spawned_player" );

	third_person = true;
	self set_third_person( true );
	//	self NotifyOnCommand( "toggle_3rd_person", "weapnext" );

	//	while( 1 )
	//	{
	//		self waittill( "toggle_3rd_person" );
	//
	//		if( third_person )
	//		{
	//			third_person = false;
	//			self set_third_person( false );
	//			wait( 0.5 );
	//		}
	//		else
	//		{
	//			third_person = true;
	//			self set_third_person( true );
	//			wait( 0.5 );
	//		}
	//	}
}


set_third_person( value )
{
	if( value )
	{
		self SetClientDvars( "cg_thirdPerson", "1",
			"cg_fov", "40",
			"cg_thirdPersonAngle", "354" );

		self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
	}
	else
	{
		self SetClientDvars( "cg_thirdPerson", "0",
			"cg_fov", "65",
			"cg_thirdPersonAngle", "0" );

		self setDepthOfField( 0, 0, 512, 4000, 4, 0 );
	}
}

spectators_respawn()
{
	level endon( "between_round_over" );

	if( !IsDefined( level.zombie_vars["spectators_respawn"] ) || !level.zombie_vars["spectators_respawn"] )
	{
		return;
	}

	if( !IsDefined( level.custom_spawnPlayer ) )
	{
		// Custom spawn call for when they respawn from spectator
		level.custom_spawnPlayer = ::spectator_respawn;
	}

	while( 1 )
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if( players[i].sessionstate == "spectator" )
			{
				players[i] [[level.spawnPlayer]]();
				if (isDefined(level.script) && level.script == "nazi_zombie_sumpf" && level.round_number > 6 && players[i].score < 1500)
				{
					players[i].old_score = players[i].score;
					players[i].score = 1500;
					players[i] maps\_zombiemode_score::set_player_score_hud();
				}
			}
		}

		wait( 1 );
	}
}

tom_single_spectator_respawn()
{
	level endon( "between_round_over" );
	if(!IsDefined(level.zombie_vars["spectators_respawn"]) || !level.zombie_vars["spectators_respawn"])
	 return;
	if(!IsDefined( level.custom_spawnPlayer))
	 level.custom_spawnPlayer = ::spectator_respawn;
	while( 1 )
	{
	 if(self.sessionstate == "spectator")
	 {
		self [[level.spawnPlayer]]();
		if(isDefined( self.has_altmelee ) && self.has_altmelee )
		 self SetPerk( "specialty_altmelee" );
		if(isDefined(level.script) && level.round_number > 6 && self.score < 1500)
	  {
		self.old_score = self.score;
		self.score = 1500;
		self maps\_zombiemode_score::set_player_score_hud();
	  }
	 }
	 wait 1;
	}
}

spectator_respawn()
{
	println( "*************************Respawn Spectator***" );
	assert( IsDefined( self.spectator_respawn ) );

	origin = self.spectator_respawn.origin;
	angles = self.spectator_respawn.angles;

	self setSpectatePermissions( false );
	
	new_origin = undefined;
	
	/#
	new_origin = check_for_valid_spawn_near_team( self );
	#/

	if( IsDefined( new_origin ) )
	{
		self Spawn( new_origin, angles );
	}
	else
	{
		self Spawn( origin, angles );
	}


	if( IsSplitScreen() )
	{
		last_alive = undefined;
		players = get_players();

		for( i = 0; i < players.size; i++ )
		{
			if( !players[i].is_zombie )
			{
				last_alive = players[i];
			}
		}

		share_screen( last_alive, false );
	}

	self.has_betties = undefined;
	self.is_burning = undefined;

	// The check_for_level_end looks for this
	self.is_zombie = false;
	self.ignoreme = false;

	setClientSysState("lsm", "0", self);	// Notify client last stand ended.
	self RevivePlayer();

	self notify( "spawned_player" );

	// Penalize the player when we respawn, since he 'died'
	self maps\_zombiemode_score::player_reduce_points( "died" );

	self thread player_zombie_breadcrumb();

	return true;
}

respawn_on_player()
{
	println( "*************************Respawn Spectator***" );
	spawn_off_player = get_closest_valid_player( self.origin );
	origin = get_safe_breadcrumb_pos( spawn_off_player );	
	self setSpectatePermissions( false );					
	if( IsDefined( origin ) )
	{
		angles = VectorToAngles( spawn_off_player.origin - origin );
	}
	else
	{
		spawnpoints = GetEntArray( "info_player_deathmatch", "classname" );
		num = RandomInt( spawnpoints.size );
		origin = spawnpoints[num].origin;
		angles = spawnpoints[num].angles;
	}
	self Spawn( origin, angles );
	if( IsSplitScreen() )
	{
		last_alive = undefined;
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if( !players[i].is_zombie )
			{
				last_alive = players[i];
			}
		}
		share_screen( last_alive, false );
	}
	if(IsSplitScreen())
	{
	 last_alive = undefined;
	 players = get_players();
	 for(i=0;i<players.size;i++)
	 {
	  if(!players[i].is_zombie)
	   last_alive = players[i];
	 }
	 share_screen( last_alive, false );
	}
	self.has_betties = undefined;
	self.is_burning = undefined;
	self.is_zombie = false;
	self.ignoreme = false;
	setClientSysState("lsm", "0", self);	
	self RevivePlayer();
	self notify( "spawned_player" );
	self maps\_zombiemode_score::player_reduce_points( "died" );
	self thread player_zombie_breadcrumb();
	return true;
}

check_for_valid_spawn_near_team( revivee )
{


	players = get_players();
	spawn_points = getstructarray("player_respawn_point", "targetname");

	if( spawn_points.size == 0 )
		return undefined;

	for( i = 0; i < players.size; i++ )
	{
		if( is_player_valid( players[i] ) )
		{
			for( j = 0 ; j < spawn_points.size; j++ )
			{
				if( DistanceSquared( players[i].origin, spawn_points[j].origin ) < ( 1000 * 1000 ) )
				{
					spawn_array = getstructarray( spawn_points[j].target, "targetname" );

					for( k = 0; k < spawn_array.size; k++ )
					{
						if( spawn_array[k].script_int == (revivee.entity_num + 1) )
						{
							return spawn_array[k].origin; 
						}
					}	

					return spawn_array[0].origin;
				}

			}

		}

	}

	return undefined;

}


get_players_on_team(exclude)
{

	teammates = [];

	players = get_players();
	for(i=0;i<players.size;i++)
	{		
		//check to see if other players on your team are alive and not waiting to be revived
		if(players[i].spawn_side == self.spawn_side && !isDefined(players[i].revivetrigger) && players[i] != exclude )
		{
			teammates[teammates.size] = players[i];
		}
	}

	return teammates;
}



get_safe_breadcrumb_pos( player )
{
	players = get_players();
	valid_players = [];

	min_dist = 150 * 150;
	for( i = 0; i < players.size; i++ )
	{
		if( !is_player_valid( players[i] ) )
		{
			continue;
		}

		valid_players[valid_players.size] = players[i];
	}

	for( i = 0; i < valid_players.size; i++ )
	{
		count = 0;
		for( q = 1; q < player.zombie_breadcrumbs.size; q++ )
		{
			if( DistanceSquared( player.zombie_breadcrumbs[q], valid_players[i].origin ) < min_dist )
			{
				continue;
			}
			
			count++;
			if( count == valid_players.size )
			{
				return player.zombie_breadcrumbs[q];
			}
		}
	}

	return undefined;
}

round_spawning()
{
	level endon( "intermission" );
/#
	level endon( "kill_round" );
#/

	if( level.intermission )
	{
		return;
	}
	
	if(level.tom_use_timer)
	{
		wait 2;
	}

	if( level.enemy_spawns.size < 1 )
	{
		ASSERTMSG( "No spawners with targetname zombie_spawner in map." ); 
		return; 
	}

/#
	if ( GetDVarInt( "zombie_cheat" ) == 2 || GetDVarInt( "zombie_cheat" ) >= 4 ) 
	{
		return;
	}
#/

	count = 0; 
	mixed_spawns = 0;
	old_spawn = undefined;
	max = undefined;
	max_dogs = 0;
	
	if(!level.tom_use_timer)
	{
		ai_calculate_health(); 

		count = 0; 

		//CODER MOD: TOMMY K
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			players[i].zombification_time = 0;
		}

		max = level.zombie_vars["zombie_max_ai"];

		multiplier = level.round_number / 5;
		if( multiplier < 1 )
		{
			multiplier = 1;
		}

		// After round 10, exponentially have more AI attack the player
		if(level.round_number >= 10)
		{
			multiplier *= level.round_number * 0.2;
		}

		max += int( ( ( get_players().size - 1 ) * level.zombie_vars["zombie_ai_per_player"] ) * multiplier ); 

		level.zombie_total = max;

		// DEBUG HACK:	
		//max = 1;
		
		if(getdvarint("realism_bosses") == 1)
		{
			if(level.round_number == level.boss_round)
			{
				maps\_rampage_util2::calculate_boss_stuff();
				level.bosses_enabled = true;
				level.boss_round = level.round_number + 4;
				iprintlnbold("^1BOSSES: "+level.bosses);
			}
		}

		mixed_spawns = 0;
		max_dogs = (get_players().size * 7) + (level.round_number * 0.15);
	}
	else if(level.tom_use_timer)
	{
		players = get_players();
		for(i=0;i<players.size;i++)
			players[i].zombification_time = 0;
	}
	
	players = get_players();
	
	if(!level.tom_use_timer)
	{
		while( count < max )
		{
			player = players[randomInt( players.size )];
			spawn_points = get_array_of_closest( player.origin, level.enemy_spawns, undefined, 7 );
			spawn_point = spawn_points[RandomInt( spawn_points.size )]; 

			while( get_enemy_count() > 26 )
			{
				continue;
				wait( 0.05 );
			}
			
				if ( IsDefined( level.mixed_rounds_enabled ) && level.mixed_rounds_enabled == 1 )
				{
					spawn_dog = false;
					if ( level.round_number == level.mix_round && mixed_spawns < max_dogs )
					{
						if ( RandomInt(100) <= 40 )
						{
							spawn_dog = true;
						}
					}

					if(getdvarint("realism_bosses") == 1)
					{
						if( level.round_number == level.boss_round && randomint(100) <= 50 )
						{
							spawn_dog = true;
						}
					}

					if ( spawn_dog )
					{
						maps\sumpf\_zombiemode_dogs::special_dog_spawn( undefined, 1 );
						level.zombie_total--;
						mixed_spawns += 1;
						wait_network_frame();
					}
				}

			ai = spawn_zombie( spawn_point ); 
			if( IsDefined( ai ) )
			{
				level.zombie_total--;
				ai thread round_spawn_failsafe();
				count++; 
			}
			wait( level.zombie_vars["zombie_spawn_delay"] ); 
			wait_network_frame();
		}

		if( level.round_number > 3 )
		{
			zombies = getaiarray( "axis" );
			while( zombies.size > 0 )
			{
				if( zombies.size == 1 && zombies[0].has_legs == true )
				{
					var = randomintrange(1, 4);
					zombies[0] set_run_anim( "sprint" + var );                       
					zombies[0].run_combatanim = level.scr_anim["zombie"]["sprint" + var];
				}
				wait(0.5);
				zombies = getaiarray("axis");
			}

		}
	}
	else if(level.tom_use_timer)
	{
		level.tom_doggy_time = false;
		level.not_just_spawned = false;
		mixed_spawns = 0;
		old_spawn = undefined;
		while(1)
		{
		 while(level.tom_limit_zom == get_enemy_count() || level.tom_stop_spawning )
			{
			if(level.tom_stop_spawning)
				{
				wait 1;
				}
		  wait 0.5;
			}
		 while( get_enemy_count() > 26)
		  wait 0.05;
		 spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )]; 
		 if(!IsDefined( old_spawn ))
		  old_spawn = spawn_point;
		 else if( Spawn_point == old_spawn )
		  spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )]; 
		 old_spawn = spawn_point;
		 if(level.enable_mix_dogs && level.tom_doggy_time)
		 {
			if(level.dogs_spawned < level.tom_dogs_to_spawn && level.not_just_spawned)
			{
				level.dogs_spawned++;
				level.not_just_spawned = false;

				maps\sumpf\_zombiemode_dogs::special_dog_spawn( undefined, 1 );
				level.zombie_total--;
				wait_network_frame();
			}
		 }
		 ai = spawn_zombie( spawn_point ); 
			if(IsDefined( ai ))
			{
			 level.zombie_total--;
			 ai thread round_spawn_failsafe();
			 count++; 
			}
			if(level.enable_mix_dogs && level.tom_doggy_time && !level.not_just_spawned)
				level.zombies_spawned++;
			wait( level.zombie_vars["zombie_spawn_delay"] ); 
			wait_network_frame();

		}
	}
}

tom_mixed_dog_crap()
{
	maps\sumpf\_zombiemode_dogs::dog_health_increase();
	level.dogs_spawned = 0;
	level.tom_doggy_time = true;
	if(level.tom_fake_round_number < 10 )
	 level.tom_dogs_to_spawn = 10;
	else if(level.tom_fake_round_number < 20 )
	 level.tom_dogs_to_spawn = 15;
	else if(level.tom_fake_round_number < 30 )
	 level.tom_dogs_to_spawn = 20;
	else if(level.tom_fake_round_number < 40 )
	 level.tom_dogs_to_spawn = 30;
	else
	 level.tom_dogs_to_spawn = 35;
	thread dog_hud();
    while(level.dogs_spawned < level.tom_dogs_to_spawn)
	{
	 if(level.zombies_spawned > 3 && !level.not_just_spawned)
	 {
	  level.not_just_spawned = true;
	  level.zombies_spawned = 0;
	 }
	 wait .4;
	}
	level.dog_round_count++;
	level.tom_doggy_time = false;
}
dog_hud()
{
if(!level.dog_hud)
 return;
    round_hud_text = create_simple_hud();
	round_hud_text.foreground = true; 
	round_hud_text.sort = 4; 
	round_hud_text.hidewheninmenu = false; 
	round_hud_text.alignX = "left"; 
	round_hud_text.alignY = "bottom";
	round_hud_text.horzAlign = "left"; 
	round_hud_text.vertAlign = "bottom";
	round_hud_text.fontScale = 2; 
	round_hud_text.x = 50;
	round_hud_text.y = -5; 
	round_hud_text.color = (1,0,0);
	round_hud_text setText("Dogs");
	round_hud_text.alpha = 1;
	level.tom_dog_hud = round_hud_text;
	while(level.tom_doggy_time)
	{
	round_hud_text fadeOverTime(1);
	round_hud_text.alpha = 0;
	wait 2;
	round_hud_text fadeOverTime(1);
	round_hud_text.alpha = 1;	
	wait 2;
	}
	round_hud_text destroy();
}

// TESTING: spawn one zombie at a time
round_spawning_test()
{
	while (true)
	{
		spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )];	// grab a random spawner

		ai = spawn_zombie( spawn_point );
		ai waittill("death");

		wait 5;
	}
}
/////////////////////////////////////////////////////////

round_text( text )
{
	if( level.first_round )
	{
		intro = true;
	}
	else
	{
		intro = false;
	}

	hud = create_simple_hud();
	hud.horzAlign = "center"; 
	hud.vertAlign = "middle";
	hud.alignX = "center"; 
	hud.alignY = "middle";
	hud.y = -100;
	hud.foreground = 1;
	hud.fontscale = 16.0;
	hud.alpha = 0; 
	hud.color = ( 1, 1, 1 );

	hud SetText( text ); 
	hud FadeOverTime( 1.5 );
	hud.alpha = 1;
	wait( 1.5 );

	if( intro )
	{
		wait( 1 );
		level notify( "intro_change_color" );
	}

	hud FadeOverTime( 3 );
	//hud.color = ( 0.8, 0, 0 );
	hud.color = ( 0.423, 0.004, 0 );
	wait( 3 );

	if( intro )
	{
		level waittill( "intro_hud_done" );
	}

	hud FadeOverTime( 1.5 );
	hud.alpha = 0;
	wait( 1.5 ); 
	hud destroy();
}

round_start()
{
	level.time2 = getTime();
	level.zombie_health = level.zombie_vars["zombie_health_start"]; 
	level.tom_fake_round_number = 1;
	level.round_number = 1; 
	level.first_round = true;

	// so players get init'ed with grenades
	players = get_players();
	for (i = 0; i < players.size; i++)
	{
		players[i] giveweapon( "stielhandgranate" );	
		players[i] setweaponammoclip( "stielhandgranate", 0);
	}

	if(!level.tom_use_timer)
	{
	 level.chalk_hud1 = create_chalk_hud();
	}
	if(level.tom_use_timer)
	  thread create_timer_hud();
	
	level.round_spawn_func = ::round_spawning;

	/#
		if (GetDVarInt("zombie_rise_test"))
		{
			level.round_spawn_func = ::round_spawning_test;		// FOR TESTING, one zombie at a time, no round advancement
		}
	#/

	if(!level.tom_use_timer)
	 level thread round_think(); 
	if(level.tom_use_timer)
	 level thread tom_background_rounds(); 
}

watch_for_break()
{
level.timer_break = false;
time = 1;
while(1)
	{
	level waittill( "between_round_over" );
	current_time = (getTime() * 0.001);
	time_passed = int(current_time - time);
	 if(time_passed >= level.avg_time_till_break)
	 {
	  level.timer_break = true;
	  wait(level.break_timeperiod);
	  time = (getTime() * 0.001);
	 }
	wait .1;
	}
}
tom_background_rounds()
{
level.dog_round_count = 1;
if(level.enable_breaks)
 thread watch_for_break();
if(level.fake_rounds_till_dogs < 3 )
	level.fake_rounds_till_dogs = 3;
level.tom_stop_spawning = false;
thread tom_slowdown();
level thread [[level.round_spawn_func]]();
thread tom_counter();
level.zombie_vars["zombie_spawn_delay"] = 3;
round_since_dog = 0;
break_j_g = false;
start = 11;
while(1)
	{
	if(level.round_number > 1 )
	 added = level.round_number * 3;
	else
	 added = 0;
	time = start + added;
	start = time;
	level.tom_round_start_time = getTime();
	level.tom_round_time = time;
	 if(level.enable_breaks)
	 {
	  wait 1;
	  if(level.timer_break)
	  {
	  level.tom_stop_spawning = true;
	  thread create_break_hud();
	    wait(level.break_timeperiod);
	  level.tom_stop_spawning = false;
	  level.tom_break_hud destroy();
	  break_j_g = true;
	  }
	  if(level.timer_break)
		level.timer_break = false;
	 }
	 if(level.enable_mix_dogs && !break_j_g)
	 {
	  if(round_since_dog == level.fake_rounds_till_dogs)
		{
		thread tom_mixed_dog_crap();
		round_since_dog = 0;
		}
	  else
		round_since_dog++;  
	 }

		if(getdvarint("realism_bosses") == 1)
		{
			if(level.round_number == level.boss_round)
			{
				thread tom_mixed_dog_crap();
				maps\_rampage_util2::calculate_boss_stuff();
				level.bosses_enabled = true;
				level.boss_round = level.round_number + 3;
				iprintlnbold("^1BOSSES: "+level.bosses);
			}
		}

	break_j_g = false;
	setDvar("tom_roundtime", time);
	wait(time);
		level.zombie_vars["zombie_spawn_delay"] = level.zombie_vars["zombie_spawn_delay"] * 0.9;
	if(level.zombie_vars["zombie_spawn_delay"] > 1.1)
		level.zombie_vars["zombie_spawn_delay"] = 1.1;
		level.round_timer = level.zombie_vars["zombie_round_time"]; 
		maxreward = 50 * level.round_number;
		if ( maxreward > 500 )
			maxreward = 500;
		level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
		players = get_players();
		ai_calculate_health(); 
		add_later_round_spawners();
		maps\_zombiemode_powerups::powerup_round_start();
		array_thread( players, maps\_zombiemode_blockers::rebuild_barrier_reward_reset );
		level thread award_grenades_for_survivors();
		level.first_round = false;
		timer = level.zombie_vars["zombie_spawn_delay"];
		if( timer < 0.08 )
			timer = 0.08; 
		level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;
		level.zombie_move_speed = level.round_number * 8;
		if(getdvarint("realism_bosses") == 1)
		{
			if(level.bosses_enabled)
			{
				level.boss_rounds_played += 1;
				level.bosses_dead = 0;
				level.total_bosses = 0;
				level.bosses_enabled = false;
				level thread boss_ammo();
			}
		}

		level.round_number++;
		level.tom_fake_round_number++;
		level notify( "between_round_over" );
	}
}
tom_ai_calculate_health()
{
if(level.min_game_time <= 6 )
	level.zombie_health = level.zombie_health + 100; 
else if(level.min_game_time <= 10 )
	level.zombie_health = level.zombie_health + 120; 
else if(level.min_game_time > 10 )
	{
	rand = randomIntRange(0.1, 0.3);
	old_p = int(level.zombie_health * rand);
	level.zombie_health = level.zombie_health + old_p;
	}
	setDvar("tom_health", level.zombie_health);
}
tom_counter()
{
level.min_game_time = 0;
	while(1)
	{
	wait 60;
	level.min_game_time++;
	}
}
tom_slowdown()
{
level.tom_limit_zom = 2;
player_size = get_players().size;
	while(1)
	{
	t_switch();
	for(i=0;i<player_size;i++)
		level.tom_limit_zom++;
	if(level.round_number == 1)
		wait 5;
	level waittill( "between_round_over" );
	if(level.round_number == 15 )
		break;
	wait 0.5;
	}
	level.tom_limit_zom = 100;
}
t_switch()
{
	level.tom_limit_zom = level.round_number + 3;
}
tom_respawn_counter()
{
start = level.tom_round_start_time * 0.001;
total = level.tom_round_time;
now = (getTime() * 0.001);
togo = (total -( now - start ));
if(togo > 180)
 togo = 180;
	hud1 = newClienthudElem(self);
	hud1.horzAlign = "center"; 
	hud1.vertAlign = "middle";
	hud1.alignX = "center"; 
	hud1.alignY = "middle";
	hud1.y = -100;
	//hud1.x =0;
	hud1.foreground = 1;
	hud1.fontscale = 1.5;
	hud1.alpha = 1; 
	hud1.color = ( 1, 1, 1 );	
	hud1 setText("Time Till Respawn");

	hud = newClientHudElem(self);
	hud.horzAlign = "center"; 
	hud.vertAlign = "middle";
	hud.alignX = "center"; 
	hud.alignY = "middle";
	hud.y = -100;
	hud.x = 82;
	hud.foreground = 1;
	hud.fontscale = 1.5;
	hud.alpha = 1; 
	hud.color = ( 1, 1, 1 );
	hud setTimer( togo );
	self.tom_respawner_hud = hud;
	self.tom_respawner_hud_time = hud1;
	wait (togo);
	if(level.spectaors_spawn_on_players)
	 self thread respawn_on_player();
	else
	 self thread tom_single_spectator_respawn();
	if(isDefined(self.tom_respawner_hud))
	 self.tom_respawner_hud destroy();
	if(isDefined(self.tom_respawner_hud_time))
	 self.tom_respawner_hud_time destroy();
}

create_timer_hud()
{
    round_hud_text = create_simple_hud();
	round_hud_text.foreground = true; 
	round_hud_text.sort = 4; 
	round_hud_text.hidewheninmenu = false; 
	round_hud_text.alignX = "left"; 
	round_hud_text.alignY = "bottom";
	round_hud_text.horzAlign = "left"; 
	round_hud_text.vertAlign = "bottom";
	round_hud_text.fontScale = 2; 
	round_hud_text.x = 5;
	round_hud_text.y = -5; 
	round_hud_text.color = (1,0,0);
	round_hud_text setTimerup(0);
	level.tom_timer_hud = round_hud_text;
}
create_break_hud()
{
if(!level.break_hud)
	return;
    round_hud_text = create_simple_hud();
	round_hud_text.foreground = true; 
	round_hud_text.sort = 4; 
	round_hud_text.hidewheninmenu = false; 
	round_hud_text.alignX = "left"; 
	round_hud_text.alignY = "bottom";
	round_hud_text.horzAlign = "left"; 
	round_hud_text.vertAlign = "bottom";
	round_hud_text.fontScale = 2; 
	round_hud_text.x = 50;
	round_hud_text.y = -5; 
	round_hud_text.color = (1,0,0);
	round_hud_text setText("Break");
	round_hud_text.alpha = 1;
	level.tom_break_hud = round_hud_text;
	while(level.tom_stop_spawning)
	{
	round_hud_text fadeOverTime(1);
	round_hud_text.alpha = 0;
	wait 2;
	round_hud_text fadeOverTime(1);
	round_hud_text.alpha = 1;	
	wait 2;
	}
}

play_intro_VO()
{
	
	wait(3);
	players = getplayers();	
	for(i=0;i<players.size;i++)
	{
		index = maps\sumpf\_zombiemode_weapons_sumpf::get_player_index(players[i]);
		player_index = "plr_" + index + "_";
		sound_to_play = "vox_name_int_0";
		players[i] 	maps\sumpf\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, 0.05);
		wait(0.7);
	}

	//Plays a random start line on one of the characters
//	i = randomintrange(0,players.size);
//	players[i] playsound ("plr_" + i + "_vox_start" + "_" + randomintrange(0, variation_count));
	
}
wait_until_first_player()
{
	players = get_players();
	if( !IsDefined( players[0] ) )
	{
		level waittill( "first_player_ready" );
	}
}

round_think()
{
	for( ;; )
	{
		//////////////////////////////////////////
		//designed by prod DT#36173
		maxreward = 50 * level.round_number;
		if ( maxreward > 500 )
			maxreward = 500;
		level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
		//////////////////////////////////////////

		level.round_timer = level.zombie_vars["zombie_round_time"]; 
		
		add_later_round_spawners();

		chalk_one_up();
		//		round_text( &"ZOMBIE_ROUND_BEGIN" );

		maps\sumpf\_zombiemode_powerups::powerup_round_start();

		players = get_players();
		array_thread( players, maps\sumpf\_zombiemode_blockers::rebuild_barrier_reward_reset );

		level thread award_grenades_for_survivors();

		level.round_start_time = getTime();
		level thread [[level.round_spawn_func]]();

		round_wait();

		level.first_round = false;

		level thread spectators_respawn();

		//		round_text( &"ZOMBIE_ROUND_END" );
		level thread chalk_round_hint();

		wait( level.zombie_vars["zombie_between_round_time"] ); 

		// here's the difficulty increase over time area
		timer = level.zombie_vars["zombie_spawn_delay"];

		if(level.round_number == level.mix_round)
		{
			level.mix_round = level.round_number + randomintrange(2,5);
		}

		if(getdvarint("realism_bosses") == 1)
		{
			if(level.bosses_enabled)
			{
				level.boss_rounds_played += 1;
				level.bosses_dead = 0;
				level.total_bosses = 0;
				level.bosses_enabled = false;
			}
		}

		if( timer < 0.08 )
		{
			timer = 0.08; 
		}	

		level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;

		// Increase the zombie move speed
		level.zombie_move_speed = level.round_number * 8;

		level.round_number++;
		
		players = get_players();
		level thread compile_bonus();
		for( i = 0; i < players.size; i++ )
		{
			players[i] thread round_bonus();
			players[i].downs1 = 0;
			players[i].headshots1 = 0;
			players[i].revives1 = 0;
			players[i].knives1 = 0;
			players[i].mostheadshots = false;
			players[i].mostrevives = false;
			players[i].hardest2kill = false;
			players[i].mostknives = false;
		}

		level notify( "between_round_over" );
	}
}

award_grenades_for_survivors()
{
	players = get_players();

	for (i = 0; i < players.size; i++)
	{
		if (!players[i].is_zombie)
		{
			if(players[i] hasWeapon("sticky_grenade"))
			{
				players[i].grenade_secondary = "sticky_grenade";
			}
			else if(players[i] hasWeapon("molotov"))
			{
				players[i].grenade_secondary = "molotov";
			}
			
			if(isDefined(players[i].grenade_secondary) && players[i].grenade_secondary != "")
			{
				if(!players[i] hasWeapon(players[i].grenade_secondary))
				{
					players[i] GiveWeapon(players[i].grenade_secondary);
				}
				players[i] SetWeaponAmmoClip(players[i].grenade_secondary,2);
			}
			
			if( !players[i] HasWeapon( "stielhandgranate" ) )
			{
				players[i] GiveWeapon( "stielhandgranate" );	
				players[i] SetWeaponAmmoClip( "stielhandgranate", 0 );
			}

			if ( players[i] GetFractionMaxAmmo( "stielhandgranate") < .25 )
			{
				players[i] SetWeaponAmmoClip( "stielhandgranate", 2 );
			}
			else if (players[i] GetFractionMaxAmmo( "stielhandgranate") < .5 )
			{
				players[i] SetWeaponAmmoClip( "stielhandgranate", 3 );
			}
			else
			{
				players[i] SetWeaponAmmoClip( "stielhandgranate", 4 );
			}
		}
	}
}

ai_calculate_health()
{
	// After round 10, get exponentially harder
	if( level.round_number >= 10 )
	{
		level.zombie_health += Int( level.zombie_health * level.zombie_vars["zombie_health_increase_percent"] ); 
		return;
	}

	if( level.round_number > 1 )
	{
		level.zombie_health = Int( level.zombie_health + level.zombie_vars["zombie_health_increase"] ); 
	}

}

//put the conditions in here which should
//cause the failsafe to reset
round_spawn_failsafe()
{
	self endon("death");//guy just died

	//////////////////////////////////////////////////////////////
	//FAILSAFE "hack shit"  DT#33203
	//////////////////////////////////////////////////////////////
	prevorigin = self.origin;
	while(1)
	{
		if( !level.zombie_vars["zombie_use_failsafe"] )
		{
			return;
		}

		wait( 30 );

		//if i've torn a board down in the last 5 seconds, just 
		//wait 30 again.
		if ( isDefined(self.lastchunk_destroy_time) )
		{
			if ( (getTime() - self.lastchunk_destroy_time) < 5000 )
				continue; 
		}

		//fell out of world
		if ( self.origin[2] < level.zombie_vars["below_world_check"] )
		{
			self dodamage( self.health + 100, (0,0,0) );	
			break;
		}

		//hasnt moved 24 inches in 30 seconds?	
		if ( DistanceSquared( self.origin, prevorigin ) < 576 ) 
		{
			// DEBUG HACK
			self dodamage( self.health + 100, (0,0,0) );	
			break;
		}

		prevorigin = self.origin;
	}
	//////////////////////////////////////////////////////////////
	//END OF FAILSAFE "hack shit"
	//////////////////////////////////////////////////////////////
}

// Waits for the time and the ai to die
round_wait()
{
	/#
		if (GetDVarInt("zombie_rise_test"))
		{
			level waittill("forever"); // TESTING: don't advance rounds
		}
#/

	/#
		if ( GetDVarInt( "zombie_cheat" ) == 2 || GetDVarInt( "zombie_cheat" ) >= 4 )
		{
			level waittill("forever");
		}
	#/

		wait( 1 );

		if( flag("dog_round" ) )
		{
			wait(7);
			while( level.dog_intermission )
			{
				wait(0.5);
			}
			
		}
		else
		{
			while( get_enemy_count() > 0 || level.zombie_total > 0 || level.intermission)
			{
				wait( 0.5 );
			}

		}
		
}

zombify_player()
{
	self maps\_zombiemode_score::player_died_penalty(); 
	self notify("death");

		// RAMPAGE - for classes
		p_class = self maps\_rampage_class::get_class();
		unlock_c = "";
		switch(p_class)
		{
			case "support_1":
				unlock_c = "support_locked";
				level.support_size = 0;
				break;

			case "soldier_1":
				unlock_c = "soldier_locked";
				level.soldier_size = 0;
				break;

			case "engineer_1":
				unlock_c = "engineer_locked";
				level.engineer_size = 0;
				break;

			case "medic_1":
				unlock_c = "medic_locked";
				level.medic_size = 0;
				break;
		}
		setDvar(unlock_c,"0");

		players = get_players();
		for(i=0;i<players.size;i++)
		{
			players[i] SetClientDvar( unlock_c,"0" );
		}

		self.class_picked = undefined;

	if( !IsDefined( level.zombie_vars["zombify_player"] ) || !level.zombie_vars["zombify_player"] )
	{
		self thread spawnSpectator(); 
		return; 
	}

	self.ignoreme = true; 
	self.is_zombie = true; 
	self.zombification_time = getTime(); 

	self.team = "axis"; 
	self notify( "zombified" ); 

	if( IsDefined( self.revivetrigger ) )
	{
		self.revivetrigger Delete(); 
	}
	self.revivetrigger = undefined; 

	self setMoveSpeedScale( 0.3 ); 
	self reviveplayer(); 

	self TakeAllWeapons(); 
	self starttanning(); 
	self GiveWeapon( "zombie_melee", 0 ); 
	self SwitchToWeapon( "zombie_melee" ); 
	self DisableWeaponCycling(); 
	self DisableOffhandWeapons(); 
	self VisionSetNaked( "zombie_turned", 1 ); 

	maps\_utility::setClientSysState( "zombify", 1, self ); 	// Zombie grain goooo

	self thread maps\sumpf\_zombiemode_spawner::zombie_eye_glow(); 

	// set up the ground ref ent
	self thread injured_walk(); 
	// allow for zombie attacks, but they lose points?

	self thread playerzombie_player_damage(); 
	self thread playerzombie_soundboard(); 
}

playerzombie_player_damage()
{
	self endon( "death" ); 
	self endon( "disconnect" ); 

	self thread playerzombie_infinite_health();  // manually keep regular health up
	self.zombiehealth = level.zombie_health; 

	// enable PVP damage on this guy
	// self EnablePvPDamage(); 

	while( 1 )
	{
		self waittill( "damage", amount, attacker, directionVec, point, type ); 

		if( !IsDefined( attacker ) || !IsPlayer( attacker ) )
		{
			wait( 0.05 ); 
			continue; 
		}

		self.zombiehealth -= amount; 

		if( self.zombiehealth <= 0 )
		{
			// "down" the zombie
			self thread playerzombie_downed_state(); 
			self waittill( "playerzombie_downed_state_done" ); 
			self.zombiehealth = level.zombie_health; 
		}
	}
}

playerzombie_downed_state()
{
	self endon( "death" ); 
	self endon( "disconnect" ); 

	downTime = 15; 

	startTime = GetTime(); 
	endTime = startTime +( downTime * 1000 ); 

	self thread playerzombie_downed_hud(); 

	self.playerzombie_soundboard_disable = true; 
	self thread maps\sumpf\_zombiemode_spawner::zombie_eye_glow_stop(); 
	self DisableWeapons(); 
	self AllowStand( false ); 
	self AllowCrouch( false ); 
	self AllowProne( true ); 

	while( GetTime() < endTime )
	{
		wait( 0.05 ); 
	}

	self.playerzombie_soundboard_disable = false; 
	self thread maps\sumpf\_zombiemode_spawner::zombie_eye_glow(); 
	self EnableWeapons(); 
	self AllowStand( true ); 
	self AllowCrouch( false ); 
	self AllowProne( false ); 

	self notify( "playerzombie_downed_state_done" ); 
}

playerzombie_downed_hud()
{
	self endon( "death" ); 
	self endon( "disconnect" ); 

	text = NewClientHudElem( self ); 
	text.alignX = "center"; 
	text.alignY = "middle"; 
	text.horzAlign = "center"; 
	text.vertAlign = "bottom"; 
	text.foreground = true; 
	text.font = "default"; 
	text.fontScale = 1.8; 
	text.alpha = 0; 
	text.color = ( 1.0, 1.0, 1.0 ); 
	text SetText( &"ZOMBIE_PLAYERZOMBIE_DOWNED" ); 

	text.y = -113; 	
	if( IsSplitScreen() )
	{
		text.y = -137; 
	}

	text FadeOverTime( 0.1 ); 
	text.alpha = 1; 

	self waittill( "playerzombie_downed_state_done" ); 

	text FadeOverTime( 0.1 ); 
	text.alpha = 0; 
}

playerzombie_infinite_health()
{
	self endon( "death" ); 
	self endon( "disconnect" ); 

	bighealth = 100000; 

	while( 1 )
	{
		if( self.health < bighealth )
		{
			self.health = bighealth; 
		}

		wait( 0.1 ); 
	}
}

playerzombie_soundboard()
{
	self endon( "death" ); 
	self endon( "disconnect" ); 

	self.playerzombie_soundboard_disable = false; 

	self.buttonpressed_use = false; 
	self.buttonpressed_attack = false; 
	self.buttonpressed_ads = false; 

	self.useSound_waitTime = 3 * 1000;  // milliseconds
	self.useSound_nextTime = GetTime(); 
	useSound = "playerzombie_usebutton_sound"; 

	self.attackSound_waitTime = 3 * 1000; 
	self.attackSound_nextTime = GetTime(); 
	attackSound = "playerzombie_attackbutton_sound"; 

	self.adsSound_waitTime = 3 * 1000; 
	self.adsSound_nextTime = GetTime(); 
	adsSound = "playerzombie_adsbutton_sound"; 

	self.inputSound_nextTime = GetTime();  // don't want to be able to do all sounds at once

	while( 1 )
	{
		if( self.playerzombie_soundboard_disable )
		{
			wait( 0.05 ); 
			continue; 
		}

		if( self UseButtonPressed() )
		{
			if( self can_do_input( "use" ) )
			{
				self thread playerzombie_play_sound( useSound ); 
				self thread playerzombie_waitfor_buttonrelease( "use" ); 
				self.useSound_nextTime = GetTime() + self.useSound_waitTime; 
			}
		}
		else if( self AttackButtonPressed() )
		{
			if( self can_do_input( "attack" ) )
			{
				self thread playerzombie_play_sound( attackSound ); 
				self thread playerzombie_waitfor_buttonrelease( "attack" ); 
				self.attackSound_nextTime = GetTime() + self.attackSound_waitTime; 
			}
		}
		else if( self AdsButtonPressed() )
		{
			if( self can_do_input( "ads" ) )
			{
				self thread playerzombie_play_sound( adsSound ); 
				self thread playerzombie_waitfor_buttonrelease( "ads" ); 
				self.adsSound_nextTime = GetTime() + self.adsSound_waitTime; 
			}
		}

		wait( 0.05 ); 
	}
}

can_do_input( inputType )
{
	if( GetTime() < self.inputSound_nextTime )
	{
		return false; 
	}

	canDo = false; 

	switch( inputType )
	{
	case "use":
		if( GetTime() >= self.useSound_nextTime && !self.buttonpressed_use )
		{
			canDo = true; 
		}
		break; 

	case "attack":
		if( GetTime() >= self.attackSound_nextTime && !self.buttonpressed_attack )
		{
			canDo = true; 
		}
		break; 

	case "ads":
		if( GetTime() >= self.useSound_nextTime && !self.buttonpressed_ads )
		{
			canDo = true; 
		}
		break; 

	default:
		ASSERTMSG( "can_do_input(): didn't recognize inputType of " + inputType ); 
		break; 
	}

	return canDo; 
}

playerzombie_play_sound( alias )
{
	self play_sound_on_ent( alias ); 
}

playerzombie_waitfor_buttonrelease( inputType )
{
	if( inputType != "use" && inputType != "attack" && inputType != "ads" )
	{
		ASSERTMSG( "playerzombie_waitfor_buttonrelease(): inputType of " + inputType + " is not recognized." ); 
		return; 
	}

	notifyString = "waitfor_buttonrelease_" + inputType; 
	self notify( notifyString ); 
	self endon( notifyString ); 

	if( inputType == "use" )
	{
		self.buttonpressed_use = true; 
		while( self UseButtonPressed() )
		{
			wait( 0.05 ); 
		}
		self.buttonpressed_use = false; 
	}

	else if( inputType == "attack" )
	{
		self.buttonpressed_attack = true; 
		while( self AttackButtonPressed() )
		{
			wait( 0.05 ); 
		}
		self.buttonpressed_attack = false; 
	}

	else if( inputType == "ads" )
	{
		self.buttonpressed_ads = true; 
		while( self AdsButtonPressed() )
		{
			wait( 0.05 ); 
		}
		self.buttonpressed_ads = false; 
	}
}

player_damage_override( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	if( iDamage < self.health )
	{
		if ( IsDefined( eAttacker ) )
		{
			eAttacker.sound_damage_player = self;
		}
		
		//iprintlnbold(iDamage);
		return;
	}
	
	if(self HasPerk("specialty_quickrevive"))
	{
		if(self.quickrevive_up2 > 0)
		{
			self.health = self.maxhealth+iDamage;
			self EnableInvulnerability();
			self notify( "second_life" );
			self.quickrevive_up2 = 0;
			self.perk_hud[ "specialty_quickrevive" ] SetShader( "specialty_pistoldeath", 20, 20 );
			self thread hud_print_self( "You Have A Second Chance" );
			self DisableInvulnerability();
			return;
		}
	}
	
	if( level.intermission )
	{
		level waittill( "forever" );
	}

	players = get_players();
	count = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] == self || players[i].is_zombie || players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator" )
		{
			count++;
		}
	}

	if( count < players.size )
	{
		return;
	}

	self.intermission = true;

	self thread maps\_laststand::PlayerLastStand( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime );
	self player_fake_death();

	if( count == players.size )
	{
		end_game();
	}
}

end_game()
{
	level.intermission = true;
	
	if(level.tom_use_timer)
	{
		tom_end_game();
		return;
	}
	
	game_difficulty = get_difficulty_text();

	update_leaderboards();

	game_over = NewHudElem( self );
	game_over.alignX = "center";
	game_over.alignY = "middle";
	game_over.horzAlign = "center";
	game_over.vertAlign = "middle";
	game_over.y -= 10;
	game_over.foreground = true;
	game_over.fontScale = 3;
	game_over.alpha = 0;
	game_over.color = ( 1.0, 1.0, 1.0 );
	game_over SetText( &"ZOMBIE_GAME_OVER" );

	game_over FadeOverTime( 1 );
	game_over.alpha = 1;

	survived = NewHudElem( self );
	survived.alignX = "center";
	survived.alignY = "middle";
	survived.horzAlign = "center";
	survived.vertAlign = "middle";
	survived.y += 20;
	survived.foreground = true;
	survived.fontScale = 2;
	survived.alpha = 0;
	survived.color = ( 1.0, 1.0, 1.0 );

	difficulty = NewHudElem( self );
	difficulty.alignX = "center";
	difficulty.alignY = "middle";
	difficulty.horzAlign = "center";
	difficulty.vertAlign = "middle";
	difficulty.y += 47;
	difficulty.foreground = true;
	difficulty.fontScale = 2;
	difficulty.alpha = 0;
	difficulty.color = ( 1.0, 1.0, 1.0 );
	difficulty setText( "^2DIFFICULTY: ", game_difficulty );
	difficulty FadeOverTime( 1 );
	difficulty.alpha = 1;

	if( level.round_number < 2 )
	{
		if( level.cheating2 < 1 )
		{
			if(getdvarint("realism_bosses") == 1)
			{
				survived SetText( &"ZOMBIE_SURVIVED_ROUND", " ^1WITH BOSSES" );
			}
			else
			{
				survived SetText( &"ZOMBIE_SURVIVED_ROUND" );
			}
		}
		else
		{
			if(getdvarint("realism_bosses") == 1)
			{
				survived setText( &"ZOMBIE_SURVIVED_ROUND", " ^1Using Cheats", " ^1WITH BOSSES" );
			}
			else
			{
				survived setText( &"ZOMBIE_SURVIVED_ROUND", " ^1Using Cheats" );
			}
		}
	}
	else
	{
		if( level.cheating2 < 1 )
		{
			if(getdvarint("realism_bosses") == 1)
			{
				survived SetText( &"ZOMBIE_SURVIVED_ROUNDS", level.round_number, " ^1WITH BOSSES" );
			}
			else
			{
				survived SetText( &"ZOMBIE_SURVIVED_ROUNDS", level.round_number );
			}
		}
		else
		{
			if(getdvarint("realism_bosses") == 1)
			{
				survived setText( &"ZOMBIE_SURVIVED_ROUNDS", level.round_number, " ^1Using Cheats", " ^1 WITH BOSSES" );
			}
			else
			{
				survived setText( &"ZOMBIE_SURVIVED_ROUNDS", level.round_number, " ^1Using Cheats" );
			}
		}
	}

	//TUEY had to change this since we are adding other musical elements
	setmusicstate("end_of_game");
	setbusstate("default");
	
	survived FadeOverTime( 1 );
	survived.alpha = 1;

	wait( 1 );

	//play_sound_at_pos( "end_of_game", ( 0, 0, 0 ) );
	wait( 2 );
	intermission();

	wait( level.zombie_vars["zombie_intermission_time"] );

	level notify( "stop_intermission" );
	array_thread( get_players(), ::player_exit_level );

	wait( 1.5 );
	
	if( is_coop() )
	{
		ExitLevel( false );
	}
	else
	{
		MissionFailed();
	}



	// Let's not exit the function
	wait( 666 );
}

tom_end_game()
{
	game_difficulty = get_difficulty_text();
	
	players = get_players();
	for(i=0;i<players.size;i++)
	{
	 if(isDefined(players[i].tom_respawner_hud))
	 {
	 players[i].tom_respawner_hud destroy();
	 players[i].tom_respawner_hud_time destroy();
	 }
	}
	add = ""; // leave for cheat shit.
	
	game_over = NewHudElem( self );
	game_over.alignX = "center";
	game_over.alignY = "middle";
	game_over.horzAlign = "center";
	game_over.vertAlign = "middle";
	game_over.y -= 10;
	game_over.foreground = true;
	game_over.fontScale = 3;
	game_over.alpha = 0;
	game_over.color = ( 1.0, 1.0, 1.0 );
	game_over SetText( "GAME OVER " + add);
	game_over FadeOverTime( 1 );
	game_over.alpha = 1;
	
	level.tom_timmer_hud FadeOverTime( 1 );
	level.tom_timmer_hud.alpha = 0;
	
	survived = NewHudElem( self );
	survived.alignX = "center";
	survived.alignY = "middle";
	survived.horzAlign = "center";
	survived.vertAlign = "middle";
	survived.y += 20;
	survived.foreground = true;
	survived.fontScale = 2;
	survived.alpha = 0;
	survived.color = ( 1.0, 1.0, 1.0 );
	
	difficulty = NewHudElem( self );
	difficulty.alignX = "center";
	difficulty.alignY = "middle";
	difficulty.horzAlign = "center";
	difficulty.vertAlign = "middle";
	difficulty.y += 47;
	difficulty.foreground = true;
	difficulty.fontScale = 2;
	difficulty.alpha = 0;
	difficulty.color = ( 1.0, 1.0, 1.0 );
	difficulty setText( "^2DIFFICULTY: ", game_difficulty );
	difficulty FadeOverTime( 1 );
	difficulty.alpha = 1;
	
	time = level.min_game_time;
	if(time < 2)
	{
		if(getdvarint("realism_bosses") == 1)
		{
			survived SetText( &"REAL_YOU_DIED_AFTER_MIN", " ^1WITH BOSSES" );
		}
		else
		{
			survived SetText( &"REAL_YOU_DIED_AFTER_MIN" );
		}
	}
	else if(time > 1)
	{
		if(getdvarint("realism_bosses") == 1)
		{
			survived SetText( &"REAL_YOU_DIED_AFTER_MINS",level.min_game_time, " ^1WITH BOSSES" );
		}
		else
		{
			survived SetText( &"REAL_YOU_DIED_AFTER_MINS",level.min_game_time );
		}
	}

	survived FadeOverTime( 1 );
	survived.alpha = 1;
	wait( 1 );
	play_sound_at_pos( "end_of_game", ( 0, 0, 0 ) );
	wait( 2 );
	intermission();
	wait( level.zombie_vars["zombie_intermission_time"] );
	level notify( "stop_intermission" );
	array_thread( get_players(), ::player_exit_level );
	bbPrint( "zombie_epilogs: rounds %d", level.round_number );
	wait 1.5;
	if(is_coop())
	 ExitLevel( false );
	else
	 MissionFailed();
	wait 666;
}

update_leaderboards()
{
	if( level.systemLink || IsSplitScreen() )
	{
		return; 
	}

	nazizombies_upload_highscore();
	nazizombies_set_new_zombie_stats();
}

player_fake_death()
{
	level notify ("fake_death");
	self notify ("fake_death");

	self TakeAllWeapons();
	self AllowStand( false );
	self AllowCrouch( false );
	self AllowProne( true );

	self.ignoreme = true;
	self EnableInvulnerability();

	wait( 1 );
	self FreezeControls( true );
}

player_exit_level()
{
	self notify("stop_tracking_time");
	
	self AllowStand( true );
	self AllowCrouch( false );
	self AllowProne( false );

	if( IsDefined( self.game_over_bg ) )
	{
		self.game_over_bg.foreground = true;
		self.game_over_bg.sort = 100;
		self.game_over_bg FadeOverTime( 1 );
		self.game_over_bg.alpha = 1;
	}
}

player_killed_override()
{
	// BLANK
	level waittill( "forever" );
}


injured_walk()
{
	self.ground_ref_ent = Spawn( "script_model", ( 0, 0, 0 ) ); 

	self.player_speed = 50; 

	// TODO do death countdown	
	self AllowSprint( false ); 
	self AllowProne( false ); 
	self AllowCrouch( false ); 
	self AllowAds( false ); 
	self AllowJump( false ); 

	self PlayerSetGroundReferenceEnt( self.ground_ref_ent ); 
	self thread limp(); 
}

limp()
{
	level endon( "disconnect" ); 
	level endon( "death" ); 
	// TODO uncomment when/if SetBlur works again
	//self thread player_random_blur(); 

	stumble = 0; 
	alt = 0; 

	while( 1 )
	{
		velocity = self GetVelocity(); 
		player_speed = abs( velocity[0] ) + abs( velocity[1] ); 

		if( player_speed < 10 )
		{
			wait( 0.05 ); 
			continue; 
		}

		speed_multiplier = player_speed / self.player_speed; 

		p = RandomFloatRange( 3, 5 ); 
		if( RandomInt( 100 ) < 20 )
		{
			p *= 3; 
		}
		r = RandomFloatRange( 3, 7 ); 
		y = RandomFloatRange( -8, -2 ); 

		stumble_angles = ( p, y, r ); 
		stumble_angles = vector_multiply( stumble_angles, speed_multiplier ); 

		stumble_time = RandomFloatRange( .35, .45 ); 
		recover_time = RandomFloatRange( .65, .8 ); 

		stumble++; 
		if( speed_multiplier > 1.3 )
		{
			stumble++; 
		}

		self thread stumble( stumble_angles, stumble_time, recover_time ); 

		level waittill( "recovered" ); 
	}
}

stumble( stumble_angles, stumble_time, recover_time, no_notify )
{
	stumble_angles = self adjust_angles_to_player( stumble_angles ); 

	self.ground_ref_ent RotateTo( stumble_angles, stumble_time, ( stumble_time/4*3 ), ( stumble_time/4 ) ); 
	self.ground_ref_ent waittill( "rotatedone" ); 

	base_angles = ( RandomFloat( 4 ) - 4, RandomFloat( 5 ), 0 ); 
	base_angles = self adjust_angles_to_player( base_angles ); 

	self.ground_ref_ent RotateTo( base_angles, recover_time, 0, ( recover_time / 2 ) ); 
	self.ground_ref_ent waittill( "rotatedone" ); 

	if( !IsDefined( no_notify ) )
	{
		level notify( "recovered" ); 
	}
}

adjust_angles_to_player( stumble_angles )
{
	pa = stumble_angles[0]; 
	ra = stumble_angles[2]; 

	rv = AnglesToRight( self.angles ); 
	fv = AnglesToForward( self.angles ); 

	rva = ( rv[0], 0, rv[1]*-1 ); 
	fva = ( fv[0], 0, fv[1]*-1 ); 
	angles = vector_multiply( rva, pa ); 
	angles = angles + vector_multiply( fva, ra ); 
	return angles +( 0, stumble_angles[1], 0 ); 
}

coop_player_spawn_placement()
{
	structs = getstructarray( "initial_spawn_points", "targetname" ); 

	flag_wait( "all_players_connected" ); 

	//chrisp - adding support for overriding the default spawning method
	if(flag("spawn_point_override"))
	{
		return;
	}
	players = get_players(); 

	for( i = 0; i < players.size; i++ )
	{
		players[i] setorigin( structs[i].origin ); 
		players[i] setplayerangles( structs[i].angles ); 
		players[i].spectator_respawn = structs[i];
	}
}


player_zombie_breadcrumb()
{
	self endon( "disconnect" ); 
	self endon( "spawned_spectator" ); 
	level endon( "intermission" );

	self.zombie_breadcrumbs = []; 
	self.zombie_breadcrumb_distance = 24 * 24; // min dist (squared) the player must move to drop a crumb
	self.zombie_breadcrumb_area_num = 3;	   // the number of "rings" the area breadcrumbs use
	self.zombie_breadcrumb_area_distance = 16; // the distance between each "ring" of the area breadcrumbs

	self store_crumb( self.origin ); 
	last_crumb = self.origin;

	self thread debug_breadcrumbs(); 

	while( 1 )
	{
		wait_time = 0.1;
		
	/#
		if( self isnotarget() )
		{
			wait( wait_time ); 
			continue;
		}
	#/

		store_crumb = true; 
		airborne = false;
		crumb = self.origin;
		
		if ( !self IsOnGround() )
		{
			airborne = true;
			store_crumb = false; 
			wait_time = 0.05;
		}
		
		if( !airborne && DistanceSquared( crumb, last_crumb ) < self.zombie_breadcrumb_distance )
		{
			store_crumb = false; 
		}

		if ( airborne && self IsOnGround() )
		{
			// player was airborne, store crumb now that he's on the ground
			store_crumb = true;
			airborne = false;
		}
		
		// PI_CHANGE_BEGIN
		// JMA - we don't need to store new crumbs, the zipline will store our destination as a crumb
		if( isDefined(level.script) && level.script == "nazi_zombie_sumpf" && (isDefined(self.on_zipline) && self.on_zipline == true))
		{
			airborne = false;
			store_crumb = false; 			
		}
		// PI_CHANGE_END

		if( store_crumb )
		{
			debug_print( "Player is storing breadcrumb " + crumb );
			last_crumb = crumb;
			self store_crumb( crumb );
		}

		wait( wait_time ); 
	}
}


store_crumb( origin )
{
	offsets = [];
	height_offset = 32;
	
	index = 0;
	for( j = 1; j <= self.zombie_breadcrumb_area_num; j++ )
	{
		offset = ( j * self.zombie_breadcrumb_area_distance );
		
		offsets[0] = ( origin[0] - offset, origin[1], origin[2] );
		offsets[1] = ( origin[0] + offset, origin[1], origin[2] );
		offsets[2] = ( origin[0], origin[1] - offset, origin[2] );
		offsets[3] = ( origin[0], origin[1] + offset, origin[2] );

		offsets[4] = ( origin[0] - offset, origin[1], origin[2] + height_offset );
		offsets[5] = ( origin[0] + offset, origin[1], origin[2] + height_offset );
		offsets[6] = ( origin[0], origin[1] - offset, origin[2] + height_offset );
		offsets[7] = ( origin[0], origin[1] + offset, origin[2] + height_offset );

		for ( i = 0; i < offsets.size; i++ )
		{
			self.zombie_breadcrumbs[index] = offsets[i];
			index++;
		}
	}
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////LEADERBOARD CODE///////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//CODER MOD: TOMMY K
nazizombies_upload_highscore()
{
	// Nazi Zombie Leaderboards
	// nazi_zombie_prototype_waves = 13
	// nazi_zombie_prototype_points = 14

	// this has gotta be the dumbest way of doing this, but at 1:33am in the morning my brain is fried!
	playersRank = 1;
	if( level.players_playing == 1 )
		playersRank = 4;
	else if( level.players_playing == 2 )
		playersRank = 3;
	else if( level.players_playing == 3 )
		playersRank = 2;

	map_name = GetDvar( "mapname" );

	if ( !isZombieLeaderboardAvailable( map_name, "waves" ) || !isZombieLeaderboardAvailable( map_name, "points" ) )
		return;

	players = get_players();		
	for( i = 0; i < players.size; i++ )
	{
		pre_highest_wave = players[i] playerZombieStatGet( map_name, "highestwave" ); 
		pre_time_in_wave = players[i] playerZombieStatGet( map_name, "timeinwave" );

		new_highest_wave = level.round_number + "" + playersRank;
		new_highest_wave = int( new_highest_wave );

		if( new_highest_wave >= pre_highest_wave )
		{
			if( players[i].zombification_time == 0 )
			{
				players[i].zombification_time = getTime();
			}

			player_survival_time = players[i].zombification_time - level.round_start_time; 
			player_survival_time = int( player_survival_time/1000 ); 			

			if( new_highest_wave > pre_highest_wave || player_survival_time > pre_time_in_wave )
			{
				rankNumber = makeRankNumber( level.round_number, playersRank, player_survival_time );

				leaderboard_number = getZombieLeaderboardNumber( map_name, "waves" );

				players[i] UploadScore( leaderboard_number, int(rankNumber), level.round_number, player_survival_time, level.players_playing ); 
				//players[i] UploadScore( leaderboard_number, int(rankNumber), level.round_number ); 

				players[i] playerZombieStatSet( map_name, "highestwave", new_highest_wave );
				players[i] playerZombieStatSet( map_name, "timeinwave", player_survival_time );	
			}
		}		

		pre_total_points = players[i] playerZombieStatGet( map_name, "totalpoints" ); 				
		if( players[i].score_total > pre_total_points )
		{
			leaderboard_number = getZombieLeaderboardNumber( map_name, "points" );

			players[i] UploadScore( leaderboard_number, players[i].score_total, players[i].kills, level.players_playing ); 

			players[i] playerZombieStatSet( map_name, "totalpoints", players[i].score_total );	
		}
	}
}

isZombieLeaderboardAvailable( map, type )
{
	if ( !isDefined( level.zombieLeaderboardNumber[map] ) )
		return 0;
	
	if ( !isDefined( level.zombieLeaderboardNumber[map][type] ) )
		return 0;

	return 1;
}

getZombieLeaderboardNumber( map, type )
{
	if ( !isDefined( level.zombieLeaderboardNumber[map][type] ) )
		assertMsg( "Unknown leaderboard number for map " + map + "and type " + type );
	
	return level.zombieLeaderboardNumber[map][type];
}

getZombieStatVariable( map, variable )
{
	if ( !isDefined( level.zombieLeaderboardStatVariable[map][variable] ) )
		assertMsg( "Unknown stat variable " + variable + " for map " + map );
		
	return level.zombieLeaderboardStatVariable[map][variable];
}

playerZombieStatGet( map, variable )
{
	stat_variable = getZombieStatVariable( map, variable );
	result = self zombieStatGet( stat_variable );

	return result;
}

playerZombieStatSet( map, variable, value )
{
	stat_variable = getZombieStatVariable( map, variable );
	self zombieStatSet( stat_variable, value );
}

nazizombies_set_new_zombie_stats()
{
	players = get_players();		
	for( i = 0; i < players.size; i++ )
	{
		//grab stat and add final totals
		total_kills = players[i] zombieStatGet( "zombie_kills" ) + players[i].stats["kills"];
		total_points = players[i] zombieStatGet( "zombie_points" ) + players[i].stats["score"];
		total_rounds = players[i] zombieStatGet( "zombie_rounds" ) + (level.round_number - 1); // rounds survived
		total_downs = players[i] zombieStatGet( "zombie_downs" ) + players[i].stats["downs"];
		total_revives = players[i] zombieStatGet( "zombie_revives" ) + players[i].stats["revives"];
		total_perks = players[i] zombieStatGet( "zombie_perks_consumed" ) + players[i].stats["perks"];
		total_headshots = players[i] zombieStatGet( "zombie_heashots" ) + players[i].stats["headshots"];
		total_zombie_gibs = players[i] zombieStatGet( "zombie_gibs" ) + players[i].stats["zombie_gibs"];

		//set zombie stats
		players[i] zombieStatSet( "zombie_kills", total_kills );
		players[i] zombieStatSet( "zombie_points", total_points );
		players[i] zombieStatSet( "zombie_rounds", total_rounds );
		players[i] zombieStatSet( "zombie_downs", total_downs );
		players[i] zombieStatSet( "zombie_revives", total_revives );
		players[i] zombieStatSet( "zombie_perks_consumed", total_perks );
		players[i] zombieStatSet( "zombie_heashots", total_headshots );
		players[i] zombieStatSet( "zombie_gibs", total_zombie_gibs );
	}
}

makeRankNumber( wave, players, time )
{
	if( time > 86400 ) 
		time = 86400; // cap it at like 1 day, need to cap cause you know some muppet is gonna end up trying it

	//pad out time
	padding = "";
	if ( 10 > time )
		padding += "0000";
	else if( 100 > time )
		padding += "000";
	else if( 1000 > time )
		padding += "00";
	else if( 10000 > time )
		padding += "0";

	rank = wave + "" + players + padding + time;

	return rank;
}


//CODER MOD: TOMMY K
/*
=============
statGet

Returns the value of the named stat
=============
*/
zombieStatGet( dataName )
{
	if( level.systemLink || true == IsSplitScreen() )
	{
		return; 
	}

	return self getStat( int(tableLookup( "mp/playerStatsTable.csv", 1, dataName, 0 )) );
}

//CODER MOD: TOMMY K
/*
=============
setStat

Sets the value of the named stat
=============
*/
zombieStatSet( dataName, value )
{
	if( level.systemLink || true == IsSplitScreen() )
	{
		return; 
	}

	self setStat( int(tableLookup( "mp/playerStatsTable.csv", 1, dataName, 0 )), value );	
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//
// INTERMISSION =========================================================== //
//

intermission()
{
	level.intermission = true;
	level notify( "intermission" );

	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		setclientsysstate( "levelNotify", "zi", players[i] ); // Tell clientscripts we're in zombie intermission

		players[i] SetClientDvars( "cg_thirdPerson", "0",
			"cg_fov", "65" );

		players[i].health = 100; // This is needed so the player view doesn't get stuck
		players[i] notify("stop_tracking_time");
		players[i] thread player_intermission();
	}

	wait( 0.25 );

	// Delay the last stand monitor so we are 100% sure the zombie intermission ("zi") is set on the cients
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		setClientSysState( "lsm", "1", players[i] );
	}

	visionset = "zombie";
	if( IsDefined( level.zombie_vars["intermission_visionset"] ) )
	{
		visionset = level.zombie_vars["intermission_visionset"];
	}

	level thread maps\_utility::set_all_players_visionset( visionset, 2 );
	level thread zombie_game_over_death();
}

zombie_game_over_death()
{
	// Kill remaining zombies, in style!
	zombies = GetAiArray( "axis" );
	for( i = 0; i < zombies.size; i++ )
	{
		if( !IsAlive( zombies[i] ) )
		{
			continue;
		}

		zombies[i] SetGoalPos( zombies[i].origin );
	}

	for( i = 0; i < zombies.size; i++ )
	{
		if( !IsAlive( zombies[i] ) )
		{
			continue;
		}

		wait( 0.5 + RandomFloat( 2 ) );

		zombies[i] maps\sumpf\_zombiemode_spawner::zombie_head_gib();
		zombies[i] DoDamage( zombies[i].health + 666, zombies[i].origin );
	}
}

player_intermission()
{
	self closeMenu();
	self closeInGameMenu();

	level endon( "stop_intermission" );

	//Show total gained point for end scoreboard and lobby
	self.score = self.score_total;

	self.sessionstate = "intermission";
	self.spectatorclient = -1; 
	self.killcamentity = -1; 
	self.archivetime = 0; 
	self.psoffsettime = 0; 
	self.friendlydamage = undefined;

	points = getstructarray( "intermission", "targetname" );

	if( !IsDefined( points ) || points.size == 0 )
	{
		points = getentarray( "info_intermission", "classname" ); 
		if( points.size < 1 )
		{
			println( "NO info_intermission POINTS IN MAP" ); 
			return;
		}	
	}

	self.game_over_bg = NewClientHudelem( self );
	self.game_over_bg.horzAlign = "fullscreen";
	self.game_over_bg.vertAlign = "fullscreen";
	self.game_over_bg SetShader( "black", 640, 480 );
	self.game_over_bg.alpha = 1;

	org = undefined;
	while( 1 )
	{
		points = array_randomize( points );
		for( i = 0; i < points.size; i++ )
		{
			point = points[i];
			// Only spawn once if we are using 'moving' org
			// If only using info_intermissions, this will respawn after 5 seconds.
			if( !IsDefined( org ) )
			{
				self Spawn( point.origin, point.angles );
			}

			// Only used with STRUCTS
			if( IsDefined( points[i].target ) )
			{
				if( !IsDefined( org ) )
				{
					org = Spawn( "script_origin", self.origin + ( 0, 0, -60 ) );
				}

				self LinkTo( org, "", ( 0, 0, -60 ), ( 0, 0, 0 ) );
				self SetPlayerAngles( points[i].angles );
				org.origin = points[i].origin;

				speed = 20;
				if( IsDefined( points[i].speed ) )
				{
					speed = points[i].speed;
				}

				target_point = getstruct( points[i].target, "targetname" );
				dist = Distance( points[i].origin, target_point.origin );
				time = dist / speed;

				q_time = time * 0.25;
				if( q_time > 1 )
				{
					q_time = 1;
				}

				self.game_over_bg FadeOverTime( q_time );
				self.game_over_bg.alpha = 0;

				org MoveTo( target_point.origin, time, q_time, q_time );
				wait( time - q_time );

				self.game_over_bg FadeOverTime( q_time );
				self.game_over_bg.alpha = 1;

				wait( q_time );
			}
			else
			{
				self.game_over_bg FadeOverTime( 1 );
				self.game_over_bg.alpha = 0;

				wait( 5 );

				self.game_over_bg FadeOverTime( 1 );
				self.game_over_bg.alpha = 1;

				wait( 1 );
			}
		}
	}
}

prevent_near_origin()
{
	while (1)
	{
		players = get_players();

		for (i = 0; i < players.size; i++)
		{
			for (q = 0; q < players.size; q++)
			{
				if (players[i] != players[q])
				{	
					if (check_to_kill_near_origin(players[i], players[q]))
					{
						p1_org = players[i].origin;
						p2_org = players[q].origin;

						wait 5;

						if (check_to_kill_near_origin(players[i], players[q]))
						{
							if ( (distance(players[i].origin, p1_org) < 30) && distance(players[q].origin, p2_org) < 30)
							{
								setsaveddvar("player_deathInvulnerableTime", 0);
								players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
								setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
							}
						}
					}	
				}
			}	
		}

		wait 0.2;
	}
}

check_to_kill_near_origin(player1, player2)
{
	if (!isdefined(player1) || !isdefined(player2))
	{
		return false;		
	}

	if (distance(player1.origin, player2.origin) > 12)
	{
		return false;
	}

	if ( player1 maps\_laststand::player_is_in_laststand() || player2 maps\_laststand::player_is_in_laststand() )
	{
		return false;
	}

	if (!isalive(player1) || !isalive(player2))
	{
		return false;		
	}

	return true;
}