--------------------------------------------------------------------------------
-- iw-menu.lua
-- This script is writen in LUA, the extension is ".sh" for compatibilities
-- reasons width menu system of X-Wrt
--
-- Description:
--        Administrative console to Chillispot
--
-- Author(s) [in order of work date]:
--       Fabi�n Omar Franzotti
--         
-- Configuration files referenced:
--
--
--------------------------------------------------------------------------------
__MENU.HotSpot.Wizard = menuClass.new()
__MENU.HotSpot.Wizard:Add("wizard_menu_general#General","iwhotspothelper.sh")
__MENU.HotSpot.Wizard:Add("wizard_menu_about#Config","iwhotspothelper.sh?option=config")
__MENU.HotSpot.Wizard:Add("wizard_menu_about#About","iwhotspothelper.sh?option=about")
__WIP = 1