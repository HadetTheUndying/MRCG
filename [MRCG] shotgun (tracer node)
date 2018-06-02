//Modular Raycast Gun (MRCG) tracer node script by Nero Revestel

//This script handles the rezzing of tracer prims which provide a visual representation of bullet trajectory and spread as defined by the core script


default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == -2)
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
            llRezObject("tracer", llGetCameraPos(), llRot2Fwd(llGetRot())*150, llGetRot(), 1);
        }
    }
}
