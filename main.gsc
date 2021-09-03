/*=================
=== Dependancies ===
==================*/
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

/*=================
====== Init =======
==================*/
init()
{
    level thread onPlayerConnect();
    level thread autoBotSpawnFunctioning();
    level.onkillscore = level.onplayerkilled;
    level.onplayerkilled = ::overwriteKilled;
    level.callDamage = level.callbackPlayerDamage;
    level.callbackPlayerDamage = ::overwriteDamage;
}


/*=================
==== Connect =====
==================*/
onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
        
        if(player is_bot())
        {
	    player thread botCantWin(); // by DoktorSAS
	}
        else
        {
       	if(!player is_bot())
       	{
	    player thread kickbot();
	}
            player thread almostHitMessage();
            player thread trackstats();
        }
    }
}

/*=================
==== Spawned =====
==================*/

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
        if (self is_bot())
        {
            self clearPerks();
            self takeAllWeapons();
            self giveweapon("knife_ballistic_mp");
            self switchToWeapon("knife_ballistic_mp");
            self setSpawnWeapon("knife_ballistic_mp");
        }
    	else 
        {
		self thread botcmd(); //cmd to add one bot
        	self thread consolekick(); //cmd to kick one bot

		/*===== First Official Spawn =====*/
	        if(isFirstSpawn)
	        {
	            self thread onFirstSpawn();
	            self freezecontrols (false);
	            isFirstSpawn = false;
        	}
		    }
	  }
}

/*=================
==== 1st Spawn =====
==================*/
onFirstSpawn() 
{
    self iPrintLnBold("^1Test!");
    wait 3;
    self iPrintLnBold("^2You can add a welcome message here!");
}


overwriteDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, boneIndex )
{
	if(!eAttacker is_bot()){
		if( sMeansofDeath != "MOD_FALLING" && sMeansofDeath != "MOD_TRIGGER_HURT" && sMeansofDeath != "MOD_SUICIDE" ) 
		{
			if ( sMeansOfDeath == "MOD_MELEE" || !isDamageWeapon( sWeapon ) ) 
			{
				eAttacker iprintln("^7Weapon does not deal damage!");
				return;
			}
			if(eAttacker isOnGround() && eAttacker isOnLast() && sMeansOfDeath != "MOD_MELEE" )
			{
				eAttacker iprintln("^1You landed!");
				return;
			}
			if(int(distance(self.origin, attacker.origin)*0.0254) < 15 && eAttacker isOnLast())
			{
				eAttacker iprintln("^1You are too close!");
				return;
			}
			iDamage = 9999;
		}

		[[level.callDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, boneIndex );        
	}

    else if(eAttacker is_bot()){
        if ( sMeansOfDeath == "MOD_MELEE" || !isBotWeapon( sWeapon ) )
        {
            iDamage = 9999;
        }

    [[level.callDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, boneIndex ); 
	
	}
}


overwriteKilled(einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration) 
{
    thread [[level.onkillscore]](einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration);
    if(attacker isOnLast())
    {
        if (self != attacker && smeansofdeath != "MOD_TRIGGER_HURT"
        && smeansofdeath != "MOD_FALLING" 
        && smeansofdeath != "MOD_SUICIDE"
        && smeansofdeath != "MOD_EXPLOSIVE")
        {
            sendMessagetoServer("^3discord.gg/plutonium"); //Discord Promotion on End Game
            sendMessagetoServer( attacker getPlayerName() + " killed ^1"  + self.name + " ^7[^1" + int(distance(self.origin, attacker.origin)*0.0254) + "m^7]");
        }
    }
}

isOnLast()
{
    return self.pers["kills"] == (level.scorelimit-1);
}

getPlayerName()
{
    name = getSubStr(self.name, 0, self.name.size);
    for(i = 0; i < name.size; i++)
    {
        if(name[i]=="]")
            break;
    }
    if(name.size != i)
        name = getSubStr(name, i + 1, name.size);
    
    return name;
}


/*================
====Bot Weapons===
================*/
isBotWeapon( weapon )
{
    if ( !isDefined ( weapon ) )
        return false;
    
    switch( weapon )
    {
        case "knife_ballistic_mp": //Allows Ballistic Knife Damage for Bots (when shooting - melee is taken care of above)
        return true;
              
        default:
             return false;        
    }

}

/*================
==Damage Weapons==
================*/

isDamageWeapon( weapon )
{
    if ( !isDefined ( weapon ) )
        return false;
    
    weapon_class = getweaponclass( weapon );
    if ( weapon_class == "weapon_sniper" || isSubStr( weapon , "sa58_" ) ) //Allows all snipers and FAL damage
        return true;
        
    switch( weapon )
    {
       case "hatchet_mp": //Allows Tomahawk Damage
             return true;
              
        default:
             return false;        
    }
}    

/*=================
=== Almost Hits ===
==================*/
almostHitMessage()
{
	self endon("disconnect");
	level endon("game_ended"); 
	
	for(;;)
	{
		self waittill("weapon_fired");
		
		if(self.pers["kills"] != level.scorelimit - 1) { // player kills != 4 
			continue;
		}
		
		start = self getTagOrigin("tag_eye");
		end = anglestoforward(self getPlayerAngles()) * 1000000;
		impact = BulletTrace(start, end, true, self)["position"];
		nearestDist = 150; // Higher nearestDist means bigger detection radius. If you change it, change it below too.
		
		foreach(player in level.players)
		{
			dist = distance(player.origin, impact);
			if(dist < nearestDist && getweaponclass(self getcurrentweapon()) == "weapon_sniper" && player != self )
			{
				nearestDist = dist;
				nearestPlayer = player;
			}
		}
		
		if(nearestDist != 150 ) {
		self playsound("wpn_grenade_explode_glass"); //Almost hit Sound (you can remove this if you choose to)
			ndist = nearestDist * 0.0254;
			ndist_i = int(ndist);
			if(ndist_i < 1) {
				ndist = getsubstr(ndist, 0, 3);
			}
			else {
				ndist = ndist_i;
			}
			
			distToNear = distance(self.origin, nearestPlayer.origin) * 0.0254; // Meters from attacker to nearest 
			distToNear_i = int(distToNear); // Round dist to int 
			if(distToNear_i < 1)
				distToNear = getsubstr(distToNear, 0, 3);
			else
				distToNear = distToNear_i;
			self iprintln("Nearly hit^1" + nearestplayer.name + "^7 (" + ndist + "m) from ^7" + disttonear + "m");
			
			nearestplayer iprintln(self.name + " ^1almost hit you from " + ndist + "m away");
			if( !isDefined(self.ahcount) )
						self.ahcount= 1;
					else
						self.ahcount+= 1;
		}
	}
}

/*==========================
===== # of Almost Hits =====
==========================*/

trackstats()
{
	self endon( "disconnect" );
	self endon( "statsdisplayed" );
	level waittill("game_ended");

	for(;;)
	{
		wait .12;
		if(!isDefined(self.biller))	
		{
			if(isDefined(self.ahcount))
			{
				wait .5;
				if(self.ahcount== 1)
					self iprintln("You almost hit ^1"+self.ahcount+" ^7time this game!");
				else
					self iprintln("You almost hit ^1"+self.ahcount+" ^7times this game!");
				self notify( "statsdisplayed" );
			}
		}
		wait 0.05;
		self notify( "statsdisplayed" );
	}
}

/*=================
====== Bots =======
==================*/

botCantWin() // by DoktorSAS
{
 	self endon("disconnect");
	level endon("game_ended");
	self.status = "BOT";
    for(;;)
    {
    	wait 0.25;
    	if(self.pers["pointstowin"] >= level.scorelimit - 4)
		{
    		self.pointstowin = 0;
			self.pers["pointstowin"] = self.pointstowin;
			self.score = 0;
			self.pers["score"] = self.score;
			self.kills = 0;
			self.deaths = 0;
			self.headshots = 0;
			self.pers["kills"] = self.kills;
			self.pers["deaths"] = self.deaths;
			self.pers["headshots"] = self.headshots;
    	}
    }
}

// Bots if Empty //
botcmd()
{
    self notifyonplayercommand( "bot_notify", "bot" );
    for(;;)
    {
    self waittill( "bot_notify" );
    self thread quikksterspawnbot();
    }

}

quikksterspawnbot()
{
    if(level.players.size > 16) {
        self iprintln("^1Max amount of bots!");
        return;
    }
    if(self.pers["team"] == "axis")
        maps/mp/bots/_bot::spawn_bot("allies");
    else
        maps/mp/bots/_bot::spawn_bot("axis");
}

kickBot()
{
    foreach(player in level.players)
    {
        if(player is_bot())
        {
            kick(player getEntityNumber());
            break;
        }
    }
}

botspawnauto( ammount )
{
    i = 0;
    if( ammount != 0 )
    {
        while( i < ammount )
        {
            quikksterspawnbot();
            i++;
        }
    }

}

autobotspawnfunctioning()
{
    wait 20;
    serversize = level.players.size;
    serverlimit = 16;
    if( serversize <= serverlimit )
    {
        botspawnauto( serverlimit - serversize );
    }
}

consoleBots(a)
{
    for(;;)
    {
        self notifyOnPlayerCommand( "spawnnotify", "spawn_bot" );
        self waittill( "spawnnotify" );
        for(i = 0; i < a; i++){
            self thread maps\mp\bots\_bot::spawn_bot("autoassign");
            wait 3;
        }
    }
}

consolekick()
{
    for(;;)
    {
        self notifyOnPlayerCommand( "kicknotify", "kickbot" );
        self waittill( "kicknotify" );
        foreach(player in level.players){
            if(isDefined(player.pers["isBot"])&& player.pers["isBot"])
            {
                kick(player getEntityNumber(),"EXE_PLAYERKICKED");
                break;
            }    
        }
    }
}
