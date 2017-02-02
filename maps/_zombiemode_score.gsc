#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility_new;

init()
{
}

player_add_points( event, mod, hit_location )
{
	self endon("disconnect");
	self endon("death");
	level endon ( "game_ended" );

	if( level.intermission )
	{
		return;
	}

	if( !is_player_valid( self ) )
	{
		return;
	}
	
	points = 0;

	switch( event )
	{
		case "death":
			points = level.zombie_vars["zombie_score_kill"]; 
			points += player_add_points_kill_bonus( mod, hit_location );
			
		
			if( mod == "MOD_MELEE" )
			{
				self.knives1 += 1;
				if((self.class_picked == "soldier_1" || self.ability == "a_soldier" || self.actual_ability == "a_soldier") && level.zombie_vars["zombie_insta_kill"] < 1)
				{
					self.soldier_melees++;
					self setstat(213, self getstat(213)+1);
					if(self getstat(213) >= 75)
					{
						self setstat(1209, self getstat(1209)+1);
						self iprintlnbold("^2You received an upgrade point!");
						self.soldier_melees = 0;
						self setstat(213, 0);
					}
					iprintlnbold(" sold_mel: "+self.soldier_melees+" STAT: "+self getstat(213));
				}
			}
			
			self.k_streak += 1;
			self notify("killed_z");
			
			break; 
	
		case "damage":
			points = 2; 
			break; 
	
		case "damage_ads":
			points = 3;
			break;
	
		default:
			assertex( 0, "Unknown point event" ); 
			break; 
	}

	points = round_up_to_ten( points ) * level.zombie_vars["zombie_point_scalar"];
	
	self.score += points; 
	self.score_total += points;
	
	self set_player_score_hud();
	
	players = get_players();
	if(players.size < 2)
	{
		kill = 500;
		self setstat(1209, self getstat(1209)+1);
		self setstat(1249, self getstat(1249)+1);
		self setstat(152, self getstat(152)+1);
	}
	else
	{
		kill = 1000;
		self setstat(1209, self getstat(1209)+1);
		self setstat(1249, self getstat(1249)+1);
		self setstat(152, self getstat(152)+1);
	}
	kill += xp_bonus( mod, hit_location );
	if(isDefined(self.double_xp))
	{
		kill *= self.double_xp;
	}
	if(event == "death")
	{
		self maps\_challenges_coop::statAdd("kills",1);
		self maps\_challenges_coop::giveRankXP( "kill", kill );
		self h_streak_bonus();
	}
}

h_streak_bonus()
{
	// Headshots
	if(self.h_streak >= self.next_h_streak)
	{
		if(!self.streak_one)
		{
			self.streak_one = true;
			self.next_h_streak_text = "Triple Rank XP";
			self iprintlnbold("Head Shot Streak ("+self.next_h_streak+"): Max Ammo");
			self.next_h_streak = self.next_h_streak + 50;
			primaryweapons = self GetWeaponsListPrimaries();
			for( i = 0; i < primaryweapons.size; i++ )
			{
				self givemaxammo( primaryweapons[i] );
			}
		}
	}
	if(self.h_streak >= self.next_h_streak)
	{
		if(!self.streak_two)
		{
			self.streak_two = true;
			self iprintlnbold("Head Shot Streak ("+self.next_h_streak+"): Triple Rank XP");
			self.streak_one = false;
			self.streak_two = false;
			self.next_h_streak = self.next_h_streak + 50;
			self thread watch_double_xp();
		}
	}
			
	// Kills
	if(self.k_streak >= self.next_k_streak)
	{
		if(self.k_streak <= 1050)
		{
			self iprintlnbold("Kill Streak ("+self.next_k_streak+"): Perk");
			self.next_k_streak = self.next_k_streak + 50;
			self thread maps\_rampage_util2::find_perk();
		}
	}
}

watch_double_xp()
{
	self endon("disconnect");
	self endon("death");
	
	self notify("p dxp");
	self endon("p dxp");
	
	self.double_xp = 3;
	wait 30;
	self.double_xp = undefined;
}

xp_bonus( mod, hit_location )
{
	if(isDefined(mod))
	{
		if( mod == "MOD_HEAD_SHOT")
		{
			return 5;
		}
		
		if( mod == "MOD_MELEE" )
		{
			return 10;
		}
	}
	
	if(isDefined(hit_location))
	{
		if(hit_location == "head" || hit_location == "helmet" || hit_location == "neck")
		{
			if(hit_location != "neck")
			{
				return 5;
			}
			return 2;
		}
	}
	return 0;
}

player_add_points_kill_bonus( mod, hit_location )
{
	if( mod == "MOD_MELEE" )
	{
		return level.zombie_vars["zombie_score_bonus_melee"]; 
	}

	if( mod == "MOD_BURNED" )
	{
		return level.zombie_vars["zombie_score_bonus_burn"];
	}

	score = 0; 

	switch( hit_location )
	{
		case "head":
		case "helmet":
			score = level.zombie_vars["zombie_score_bonus_head"]; 
			break; 
	
		case "neck":
			score = level.zombie_vars["zombie_score_bonus_neck"]; 
			break; 
	
		case "torso_upper":
		case "torso_lower":
			score = level.zombie_vars["zombie_score_bonus_torso"]; 
			break; 
	}

	return score; 
}

player_reduce_points( event, mod, hit_location )
{
	if( level.intermission )
	{
		return;
	}

	points = 0; 

	switch( event )
	{
		case "no_revive_penalty":
			percent = level.zombie_vars["penalty_no_revive_percent"];
			points = self.score * percent;
			break; 
	
		case "died":
			self maps\_challenges_coop::statAdd("deaths",1);
			percent = level.zombie_vars["penalty_died_percent"];
			points = self.score * percent;
			break; 

		case "downed":
			self.downs1 += 1;
			self.h_streak = 0;
			self.streak_one = false;
			self.streak_two = false;
			self.streak_three = false;
			percent = level.zombie_vars["penalty_downed_percent"];;
			self notify("I_am_down");
			points = self.score * percent;
			self.score_lost_when_downed = round_up_to_ten( int( points ) );
			break; 
	
		default:
			assertex( 0, "Unknown point event" ); 
			break; 
	}

	points = self.score - round_up_to_ten( int( points ) );

	if( points < 0 )
	{
		points = 0;
	}

	self.score = points;
	
	self set_player_score_hud(); 
}

add_to_player_score( cost )
{
	if( level.intermission )
	{
		return;
	}

	self.score += cost; 

	// also set the score onscreen
	self set_player_score_hud(); 
}

minus_to_player_score( cost )
{
	if( level.intermission )
	{
		return;
	}

	self.score -= cost; 

	// also set the score onscreen
	self set_player_score_hud(); 
}

player_died_penalty()
{
	p_class = self maps\_rampage_class::get_class();
	unlock_c = "";
	switch(p_class)
	{
		case "support_1":
			unlock_c = "rampage_whosupport";
			break;

		case "soldier_1":
			unlock_c = "rampage_whosoldier";
			break;

		case "engineer_1":
			unlock_c = "rampage_whoengineer";
			break;

		case "medic_1":
			unlock_c = "rampage_whomedic";
			break;
	}
	setDvar(unlock_c, "");
		
	// Penalize all of the other players
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		players[i] setclientdvar(unlock_c, "");
		if( players[i] != self && !players[i].is_zombie )
		{
			players[i] player_reduce_points( "no_revive_penalty" );
		}
	}
}

player_downed_penalty()
{
	self player_reduce_points( "downed" );
}

//
// SCORING HUD --------------------------------------------------------------------- //
//

// Updates player score hud
set_player_score_hud( init )
{
	num = self.entity_num; 

	score_diff = self.score - self.old_score; 

	self thread score_highlight( self.score, score_diff ); 

	if( IsDefined( init ) )
	{
		return; 
	}

	self.old_score = self.score; 
}

// Create the huds and sets values/text to the hudelems on the upper left
//create_player_score_hud()
//{
//	// TODO: We need to clean up the score huds if a player disconnects
//
//	if( !IsDefined( level.score_leaders ) )
//	{
//		level.score_leaders = []; 
//	}
//
//	level.score_leaders[level.score_leaders.size] = self; 
//
//	if( !IsDefined( level.hud_scores ) )
//	{
//		if( is_coop() )
//		{
//			level.hud_names = []; 
//		}
//
//		level.hud_scores = []; 	
//	}
//
//	level.hud_y_size = 20; 
//	level.hud_score_x_offset = 100; 
//
//	num = self.entity_num; 
//	y = level.hud_scores.size * level.hud_y_size; 
//
//	// Only show the names if we're playing coop. 
//	if( is_coop() && !IsSplitscreen() )
//	{
//		level.hud_names[num] = create_score_hud( 0, y ); 
//		level.hud_names[num] SetText( self ); 
//
//		level.hud_scores[num] = create_score_hud( level.hud_score_x_offset, y ); 
//	}
//	else
//	{
//		level.hud_scores[num] = create_score_hud( 0, 0, true ); 
//	}
//}

// Creates the actual hudelem that will always show up on the upper left
//create_score_hud( x, y, playing_sp )
//{
//	font_size = 8; 
//
//	// Use newclienthudelem if playing sp or splitscreen
//	if( IsDefined( playing_sp ) && playing_sp )
//	{
//		font_size = 16; 
//		hud = NewClientHudElem( self ); 
//	}
//	else
//	{
//		hud = NewHudElem(); 
//	}
//
//	level.hudelem_count++; 
//
//	hud.foreground = true; 
//	hud.sort = 1; 
//	hud.x = x; 
//	hud.y = y; 
//	hud.fontScale = font_size; 
//	hud.alignX = "left"; 
//	hud.alignY = "middle"; 
//	hud.horzAlign = "left"; 
//	hud.vertAlign = "top"; 
//	hud.color = ( 0.8, 0.0, 0.0 ); 
////	hud.glowColor = ( 0, 1, 0 ); 
////	hud.glowAlpha = 1; 
//	hud.hidewheninmenu = false; 
//	
//	return hud; 
//}

//sort_score_board( init )
//{
//	// Figure out the order by score
//	players = get_players(); 
//	for( i = 0; i < players.size; i++ )
//	{
//		for( q = i; q < players.size; q++ )
//		{
//			if( players[q].score > players[i].score )
//			{
//				temp = players[i]; 
//				players[i] = players[q]; 
//				players[q] = temp; 
//			}
//		}
//	}
//
//	// Place the scores in order by score
//	for( i = 0; i < players.size; i++ )
//	{
//		num = players[i].entity_num; 
//		y = i * 20;
//
//		if( IsDefined( level.hud_scores[num] ) )
//		{
//			if( level.hud_scores[num].y != y )
//			{
//				level.hud_scores[num].y = y;
//				level.hud_names[num].y  = y; 
//			}
//		}
//	}
//}

// Creates a hudelem used for the points awarded/taken away
create_highlight_hud( x, y, value )
{
	font_size = 8; 

	if( IsSplitScreen() )
	{
		hud = NewClientHudElem( self );
	}
	else
	{
		hud = NewHudElem();
	}

	level.hudelem_count++; 

	hud.foreground = true; 
	hud.sort = 0; 
	hud.x = x; 
	hud.y = y; 
	hud.fontScale = font_size; 
	hud.alignX = "right"; 
	hud.alignY = "middle"; 
	hud.horzAlign = "right";
	hud.vertAlign = "bottom";

	if( value < 1 )
	{
//		hud.color = ( 0.8, 0, 0 ); 
		hud.color = ( 0.423, 0.004, 0 );
	}
	else
	{
		hud.color = ( 0.9, 0.9, 0.0 );
		hud.label = &"SCRIPT_PLUS";
	}

//	hud.glowColor = ( 0.3, 0.6, 0.3 );
//	hud.glowAlpha = 1; 
	hud.hidewheninmenu = false; 

	hud SetValue( value ); 

	return hud; 	
}

// Handles the creation/movement/deletion of the moving hud elems
score_highlight( score, value )
{
	self endon( "disconnect" ); 

	// Location from hud.menu
	score_x = -103;
	score_y = -71;

	x = score_x;

	if( IsSplitScreen() )
	{
		y = score_y;
	}
	else
	{
		players = get_players();
		num = ( players.size - self GetEntityNumber() ) - 1;
		y = ( num * -18 ) + score_y;
	}
//	places = places_before_decimal( score ) - 1; 

//	if( IsDefined( playing_sp ) && playing_sp )
//	{
//		// Adds more to the X if the score is larger
//		x += places * 20; 
//	}
//	else // playing coop
//	{
//		x = level.hud_score_x_offset; 
//		y = level.hud_scores[self.entity_num].y;

		// Adds more to the X if the score is larger
//		x += places * 10; 
//	}

	time = 0.5; 
	half_time = time * 0.5; 

	hud = create_highlight_hud( x, y, value ); 

	// Move the hud
	hud MoveOverTime( time ); 
	hud.x -= 20 + RandomInt( 40 ); 
	hud.y -= ( -15 + RandomInt( 30 ) ); 

	wait( half_time ); 

	// Fade half-way through the move
	hud FadeOverTime( half_time ); 
	hud.alpha = 0; 

	wait( half_time ); 

	hud Destroy(); 
	level.hudelem_count--; 
}