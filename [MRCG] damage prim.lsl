// DROP ME INTO A NEWLY-REZZED PLYWOOD CUBE, THEN PLACE THAT CUBE INSIDE OF GUN CONTENTS.


list lst;
vector pos0;
vector pos;

default
{
    state_entry()
    {
        llSetObjectName("[MRCG] damage");
        llSetPhysicsMaterial(GRAVITY_MULTIPLIER, 1.0, 0.0, 0.0, 0.0);
        llSetAlpha(0, ALL_SIDES);
        llLinkParticleSystem(LINK_SET, []);
        llSetScale(<0.15, 0.15, 0.15>);
        llCollisionSound("", 0.0);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z | STATUS_PHYSICS, FALSE);
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
        llSetDamage(0);
    }
    
    on_rez(integer sp)
    {
        key rezzer = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        string rezzerdesc = llList2String(llGetObjectDetails(rezzer, [OBJECT_DESC]), 0);
        llSetObjectName(rezzerdesc+" dmg");
        llSetDamage((integer)rezzerdesc);
        llResetTime();
        key id = llList2Key(llGetAgentList(AGENT_LIST_REGION, []), sp);
        vector pos;
        vector vel;
        list details;
        do{
            if(llGetTime() >= 6)llDie();
            pos0 = llList2Vector(lst = llGetObjectDetails(id, [OBJECT_POS, OBJECT_VELOCITY]), 0);
            llSetRegionPos(pos = llList2Vector(lst = llGetObjectDetails(id, [OBJECT_POS, OBJECT_VELOCITY]), 0));
            llSetVelocity(1.2 * llList2Vector(lst, 1) - <0.0, 0.0, 0.1>, FALSE);
            llSleep(0.022);
            llSetStatus(STATUS_PHYSICS | STATUS_PHANTOM, FALSE);
            llSleep(0.022);
            //if(llVecDist(llGetPos(), pos) <= 0.2 && llGetAgentInfo(id)&AGENT_SITTING)llSetStatus(STATUS_PHYSICS, TRUE);else if(llGetAgentInfo(id)&AGENT_SITTING)llSetStatus(STATUS_PHYSICS, FALSE);
            if(llGetParcelFlags(pos)&PARCEL_FLAG_ALLOW_DAMAGE){}else{llDie();}
        }while(pos != ZERO_VECTOR);
        llDie();
    }
}
