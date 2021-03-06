//Modular Raycast Gun (MRCG) core script by Nero Revestel


//NOTE: In these annotations, the word "bullet" is reference to the simulated shots projected via detection area refinement algorithms





//SETTINGS__________________________________________

string gun_type = "Sniper Rifle"; //the type of gun this script is configured for, used only for reference

integer damage = 100; //amount of damage each bullet deals

integer falloff_damage = 70; //damage value for all hits beyond [falloff_range]

integer LBA_damage = 10; //anti-armor damage dealt to LBA objects

float falloff_range = -50.0; //range in meters at which bullets begin to deal diminished damage. Set to a negative value to invert the falloff, having the [falloff_damage] occur between you and the [falloff_range], rather than between the [falloff_range] and the [max_range]

float max_range = 400.0; //range in meters at which bullets begin to deal no damage (zero damage is dealt because the max raycast length is defined by this variable)

float firing_rate = 1.3; //delay in seconds between each shot (set to 0 for fastest possible firing rate)

float detection_radius = 0.8; //radius in meters of the projected cylindrical detection area for each shot

integer magazine_size = 6; //number of bullets that can be fired per reload

float reload_speed = 3.0; //time it takes in seconds to reload the gun



/*EFFECTS__________________________________________

(If a setting is not applicable, leave it empty to disable it)*/

//GENERAL

float volume = 0.5; //volume of all sounds played

//SOUNDS

string firing_sound = "807fb692-a0ef-e236-555a-c2d536bbd7ee"; //looping gunshot sound to be played while trigger is held

string reload_sound = "fbfd446c-4dbc-4b69-23cc-9665d078d030"; //sound played when reloading the gun

string hit_sound = "2c1b90f4-c7b2-713e-71f1-d8d25e829f7a"; //sound played when a bullet hits an avatar for full damage

string hit_sound_falloff = "2c1b90f4-c7b2-713e-71f1-d8d25e829f7a"; //sound played when a bullet hits an avatar beyond [falloff_range]

string holster_sound = ""; //sound played when holstering the gun

string unholster_sound = ""; //sound played when unholstering the gun

//ANIMATIONS

string firing_animation = ""; //looping animation to be played while trigger is held

string aiming_animation = "aim"; //looping animation to be played while avatar is in mouselook

string holding_animation = "hold"; //looping animation to be played while avatar is out of mouselook

string reload_animation = "reload"; //animation played when reloading the gun

string holster_animation = ""; //animation played when holstering the gun

string unholster_animation = ""; //animation played when unholstering the gun



//CHAT COMMANDS__________________________________________

integer listen_channel = 1; //channel for listening to all chat commands and gesture triggers (for reloading and holstering, etc.)

string holster_command = "toggle_holster"; //chat command for toggling the gun holster

string reload_command = "reload"; //chat command for reloading the gun





/*___________________________________________
NOTE: DON'T TOUCH ANYTHING BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING!
___________________________________________*/





//GLOBAL VARIABLES__________________________________________

integer magazine;
integer override = 0;



//FUNCTIONS__________________________________________

sleep(float time) //function to replace llSleep for more consistency and accuracy to real-life time. DO NOT TOUCH THIS.
{
    llResetTime();
    do{llSleep(0.022);}while(llGetTime()<time);
}

integer check_los(vector start_pos, vector end_pos)
{
    list ray = llCastRay(start_pos, end_pos, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
    if((key)llList2String(ray, 0) == "0")
    {
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

Unholster() //function for unholstering the gun
{
    if(unholster_animation != "")
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        llStartAnimation(unholster_animation);
    }
    if(unholster_sound != "")llPlaySound(unholster_sound, volume);
    llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
    llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
    llTakeControls(CONTROL_ML_LBUTTON, TRUE, FALSE);
}

Holster() //function for holstering the gun
{
    if(holster_animation != "")
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        llStartAnimation(holster_animation);
    }
    if(holster_sound != "")llPlaySound(holster_sound, volume);
    llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    llReleaseControls();
}

Reload() //function for reloading the gun
{
    if(reload_animation != "")
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        llStartAnimation(reload_animation);
    }
    if(reload_sound != "")llPlaySound(reload_sound, volume);
    sleep(reload_speed);
    magazine = magazine_size;
}

ShootBullet() //function that simulates a "shot" using detection area refinement math on a list of potential targets within the region
{
    if(firing_sound != "")llTriggerSound(firing_sound, volume);
    if(firing_animation != "")
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        llStartAnimation(firing_animation);
    }
    llMessageLinked(LINK_SET, -2, "", "");
    list agentlist = llGetAgentList(AGENT_LIST_REGION, []);
    integer listlength = llGetListLength(agentlist);
    integer i;
    llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
    LBA_AT((key)llList2String(llCastRay(llGetCameraPos(), llGetCameraPos()+llRot2Fwd(llGetRot())*max_range, [RC_REJECT_TYPES, RC_REJECT_AGENTS, RC_DATA_FLAGS, RC_GET_ROOT_KEY]), 0), LBA_damage);
    for(i = listlength+1; i; i--)
    {
        vector pos = llGetCameraPos();
        key target = (key)llList2String(agentlist, i-1);
        list details = llGetObjectDetails(target, [OBJECT_POS]);
        vector targetpos = (vector)llList2String(details, 0);
        vector targetsize = llGetAgentSize(target);
        float dist = llVecDist(pos, targetpos);
        vector projectedpos = pos+llRot2Fwd(llGetRot())*dist;
        if(llVecDist(projectedpos, targetpos) <= detection_radius && target != llGetOwner())
        {
        @retry;
        if(check_los(pos, targetpos) || override)
        {
            //the current target is "hit" because their position is within the projected cylindrical detection zone
            override = 0;
            integer dmg;
            if((falloff_range > 0 && dist > falloff_range) || (falloff_range < 0 && dist < llFabs(falloff_range)))
            {
                dmg = falloff_damage;
            }
            else
            {
                dmg = damage;
            }
            
            if(dmg == damage)
            {
                if(hit_sound != "")llTriggerSound(hit_sound, volume);
            }
            else
            {
                if(hit_sound_falloff != "")llTriggerSound(hit_sound_falloff, volume);
            }
            llSetObjectDesc((string)dmg);
            llRegionSay(-777, (string)target + "," + (string)dmg + "," + gun_type + "," + (string)damage + "," + (string)falloff_damage + "," + (string)LBA_damage + "," + (string)falloff_range + "," + (string)max_range + "," + (string)firing_rate + "," + (string)detection_radius + "," + (string)magazine_size + "," + (string)reload_speed);
            llRezObject("[MRCG] damage", llGetPos()+<0.,0.,5.>, ZERO_VECTOR, llGetRot(), (integer)llListFindList(llGetAgentList(AGENT_LIST_REGION, []), [target]));
            string name = llGetObjectName();
            llSetObjectName(">");
            llOwnerSay("/me "+llKey2Name(target)+"  |  "+(string)dmg+"dmg");
            llSetObjectName(name);
        }
        else if(check_los(pos, targetpos+<0.,0.,targetsize.z/2>))
        {
            override = 1;
            jump retry;
        }
        else if(check_los(pos, targetpos-<0.,0.,targetsize.z/1.5>))
        {
            override = 1;
            jump retry;
        }
        }
    }
}

LBA_AT(key id, integer dmg)
{
    integer hex = (integer)("0x" + llGetSubString(llMD5String((string)id,0), 0, 3));
    llRegionSayTo(id,hex,(string)id+","+(string)dmg);
    llRegionSayTo(id,-500,(string)id+",damage,"+(string)dmg);
}





default
{
    attach(key id)
    {
        llSleep(1.0);
        llResetScript();
    }
    
    state_entry()
    {
        if(!llGetAttached())return;
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        llTakeControls(CONTROL_ML_LBUTTON, TRUE, FALSE);
        magazine = magazine_size;
        llSetTimerEvent(0.55);
        llListen(listen_channel, "", llGetOwner(), "");
        llListen(-777, "", "", "");
    }
    
    listen(integer c, string n, key id, string m)
    {
        if(m == holster_command)
        {
            Holster();
            llSleep(0.022);
            state holstered;
        }
        else if(m == reload_command && magazine != magazine_size)
        {
            Reload();
        }
        else
        {
            list enemy_stats = llParseString2List(m, [","], [""]);
            if((key)llList2String(enemy_stats, 0) == llGetOwner())
            {
                string enemy = llKey2Name(llList2String(llGetObjectDetails(id, [OBJECT_OWNER]), 0));
                string enemy_dmg = llList2String(enemy_stats, 1);
                string name = llGetObjectName();
                llSetObjectName("<");
                llOwnerSay("/me "+enemy+"  |  "+enemy_dmg+"dmg");
                llSetObjectName(name);
            }
        }
    }

    control(key id, integer level, integer edge)
    {
        if(level & edge & CONTROL_ML_LBUTTON && llGetTime() >= firing_rate)
        {
            //shot is fired
            ShootBullet();
            magazine -= 1;
            llResetTime();
            if(magazine <= 0)Reload();
        }
    }
    
    timer()
    {
        if(!llGetAttached())return;
        if(llGetAgentInfo(llGetOwner())&AGENT_MOUSELOOK)
        {
            //continuously triggered while in mouselook
            if(aiming_animation != "")
            {
                llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
                llStartAnimation(aiming_animation);
            }
            if(holding_animation != "")
            {
                llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
                llStopAnimation(holding_animation);
            }
        }
        else
        {
            //continously triggered while out of mouselook
            if(holding_animation != "")
            {
                llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
                llStartAnimation(holding_animation);
            }
            if(aiming_animation != "")
            {
                llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
                llStopAnimation(aiming_animation);
            }
        }
    }
}



state holstered
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        if(firing_animation != "")llStopAnimation(firing_animation);
        if(aiming_animation != "")llStopAnimation(aiming_animation);
        if(holding_animation != "")llStopAnimation(holding_animation);
        llListen(listen_channel, "", llGetOwner(), "");
    }
    
    listen(integer c, string n, key id, string m)
    {
        if(m == holster_command)
        {
            Unholster();
            llSleep(0.022);
            state default;
        }
    }
}
