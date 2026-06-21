
function OutputDoodadTip(dwDoodadID)
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return
	end

	local player = GetClientPlayer()
	local bQuestDoodad = doodad.nKind == DOODAD_KIND.QUEST
	if bQuestDoodad and not doodad.HaveQuest(player.dwID) then
	    return
	end

	if not doodad.IsSelectable() then
	    return
	end

	local szTip = ""

	--------------名字-------------------------
	local szDoodadName = GBKToUTF8(Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID))

    if doodad.nKind == DOODAD_KIND.CORPSE then
    	szName = szDoodadName .. g_tStrings.STR_DOODAD_CORPSE
    end

    szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(szDoodadName.."\n").." font=37 </text>"

	if (doodad.nKind == DOODAD_KIND.CORPSE and not doodad.CanLoot(player.dwID)) or doodad.nKind == DOODAD_KIND.CRAFT_TARGET then
    	local doodadTemplate = GetDoodadTemplate(doodad.dwTemplateID);
    	if doodadTemplate.dwCraftID ~= 0 then
    		local dwRecipeID = doodad.GetRecipeID()
	    	local recipe = GetRecipe(doodadTemplate.dwCraftID, dwRecipeID);
	    	if recipe then
	    		--生活技能等级--
	    		local profession = GetProfession(recipe.dwProfessionID);
	    		local requireLevel = recipe.dwRequireProfessionLevel;

	    		--local playMaxLevel               = player.GetProfessionMaxLevel(recipe.dwProfessionID)
	            local playerLevel                = player.GetProfessionLevel(recipe.dwProfessionID)
	            --local playExp                    = player.GetProfessionProficiency(recipe.dwProfessionID)

	    		local nDis = playerLevel - requireLevel
	    		local nFont = 101
				if not player.IsProfessionLearnedByCraftID(doodadTemplate.dwCraftID) then
					nFont = 102
				end

				if doodadTemplate.dwCraftID == 1 or doodadTemplate.dwCraftID == 2 or doodadTemplate.dwCraftID == 3 then --采金 神农 庖丁
					szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(FormatString(g_tStrings.STR_MSG_NEED_BEST_CRAFT, Table_GetProfessionName(recipe.dwProfessionID), requireLevel)).." font="..nFont.." </text>"
				elseif doodadTemplate.dwCraftID ~= 8 then --8 读碑文
					szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(FormatString(g_tStrings.STR_MSG_NEED_CRAFT, Table_GetProfessionName(recipe.dwProfessionID), requireLevel)).." font="..nFont.." </text>"
				end

                if recipe.nCraftType == ALL_CRAFT_TYPE.READ then
                    if recipe.dwProfessionIDExt ~= 0 then
            		    local nBookID, nSegmentID = GlobelRecipeID2BookID(dwRecipeID)
          				if player.IsBookMemorized(nBookID, nSegmentID) then
							szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(g_tStrings.TIP_ALREADY_READ).." font=108 </text>"
						else
							szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(g_tStrings.TIP_UNREAD).." font=105 </text>"
						end

        		    end
        		end

	    		if recipe.dwToolItemType ~= 0 and recipe.dwToolItemIndex ~= 0 and doodadTemplate.dwCraftID ~= 8 then
	    			local hasItem = player.GetItemAmount(recipe.dwToolItemType, recipe.dwToolItemIndex)
					local hasCommonItem = player.GetItemAmount(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)
	    			local toolItemInfo = GetItemInfo(recipe.dwToolItemType, recipe.dwToolItemIndex)
					local toolCommonItemInfo = GetItemInfo(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)
	    			local nFont = 102
	    			if hasItem > 0 or hasCommonItem > 0 then
	    				nFont = 106
	    			end

					if toolCommonItemInfo then
						szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(FormatString(g_tStrings.STR_MSG_NEED_TOOL, GBKToUTF8(ItemData.GetItemNameByItemInfo(toolItemInfo)) .. g_tStrings.STR_OR .. GBKToUTF8(ItemData.GetItemNameByItemInfo(toolCommonItemInfo)))).." font="..nFont.." </text>"
					else
						szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(FormatString(g_tStrings.STR_MSG_NEED_TOOL, GBKToUTF8(ItemData.GetItemNameByItemInfo(toolItemInfo)))).." font="..nFont.." </text>"
					end

				end

				if recipe.nCraftType == ALL_CRAFT_TYPE.COLLECTION then
            		local nFont = 102
    	    	    if player.IsVigorAndStaminaEnough(recipe.nVigor) then
    	    		    nFont = 106
    	    		end
            		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_COST_VIGOR, recipe.nVigor), nFont)
				elseif recipe.nCraftType == ALL_CRAFT_TYPE.PRODUCE  or recipe.nCraftType == ALL_CRAFT_TYPE.READ or recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
            	    local nFont = 102
    	    	    if player.IsVigorAndStaminaEnough(recipe.nVigor)  then
    	    		    nFont = 106
    	    		end
            		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_COST_VIGOR, recipe.nVigor), nFont)
            	end
	    	end
	    end
    end

    local szDoodadQuestTip = GetDoodadQuestTip(doodad.dwTemplateID)
    szTip = szTip .. szDoodadQuestTip

    ------------模版ID-----------------------
    --if IsCtrlKeyDown() then
    	szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(FormatString(g_tStrings.TIP_DOODAD_ID, doodad.dwID)).." font=102 </text>"
    	szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(FormatString(g_tStrings.TIP_TEMPLATE_ID, doodad.dwTemplateID)).." font=102 </text>"
    	szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(FormatString(g_tStrings.TIP_REPRESENTID_ID, doodad.dwRepresentID)).." font=102 </text>"
    --end

    return szDoodadName, szTip
end

function GetDoodadQuestTip(dwDoodadTemplateID)
	local nTargetFont = 0
	szTip = ""
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return szTip
	end

	local tQuestList = hPlayer.GetQuestList()
	for _, dwQuestID in pairs(tQuestList) do
		local szTarget = ""
		local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
		local tQuestInfo = GetQuestInfo(dwQuestID)
		for i = 1, QUEST_COUNT.QUEST_END_ITEM_COUNT do
			if tQuestInfo["dwDropItemDoodadTemplateID" .. i] ~= 0
			and tQuestInfo["dwDropItemDoodadTemplateID" .. i] == dwDoodadTemplateID
			then
				for _, v in ipairs(tQuestTrace.need_item) do
					if v.type == tQuestInfo["dwEndRequireItemType" .. i]
					and v.index == tQuestInfo["dwEndRequireItemIndex" .. i]
					and v.need == tQuestInfo["dwEndRequireItemAmount" .. i]
					then
						local tItemInfo = GetItemInfo(v.type, v.index)
						local nBookID = v.need
						if tItemInfo.nGenre == ITEM_GENRE.BOOK then
							v.need = 1
						end
						if v.have < v.need then
							local szName = "Unknown Item"
							if tItemInfo then
								szName = ItemData.GetItemNameByItemInfo(tItemInfo, nBookID)
							end
							szTarget = szTarget .. GetFormatText(g_tStrings.STR_TWO_CHINESE_SPACE.. szName ..": "..v.have.."/"..v.need .. "\n", nTargetFont)
						end
						break
					end
				end
			end
		end
		if szTarget ~= "" then
			local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
			szTip = szTip .. GetFormatText("[" .. tQuestStringInfo.szName .. "]\n", 65) .. szTarget
		end
	end
	return szTip
end


function GetActionNameByDoodad(nDoodadId)
	assert(nDoodadId)
	local doodad = GetDoodad(nDoodadId)
	assert(doodad, "----> fail to get doodad by id: " .. nDoodadId)
end


function CheckDistanceAndDirection(player, doodad)
	if not doodad.CanDialog(player) then
		--OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.TIP_TOO_FAR)
		--print("MSG_ANNOUNCE_NORMAL", g_tStrings.TIP_TOO_FAR)
		return false
	end

	return true
end

function OpenDoodad(player, doodad)
	local bResult = CheckDistanceAndDirection(player, doodad)
	if not bResult then
		return false
	end

    player.Open(doodad.dwID)
	LOG.INFO("----> player.Open: %d", doodad.dwID)

	--教学 操作Doodad
    FireHelpEvent("OnOpenDoodad", doodad.dwTemplateID)
    return true
end



--需要攻击返回false，否则返回true
function InteractDoodad(dwDoodadID)
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
        LOG.ERROR("[UI InteractDoodad] error get dooad("..dwDoodadID..")\n")
		return true
	end

	local player = GetClientPlayer()
	local dwPlayerID = player.dwID

	--[[
	LootList_SetPickupAll(false)
	if IsShiftKeyDown() or LootList_IsRButtonPickupAll() then
		LootList_SetPickupAll(true)
	end
	--]]

	local doodadTemplate = GetDoodadTemplate(doodad.dwTemplateID)
	if not doodadTemplate then
        LOG.ERROR("[UI InteractDoodad] error get dooadTemplate("..doodad.dwTemplateID..")\n")
		return true
	end

	if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
		if doodad.CanLoot(dwPlayerID) then
				OpenDoodad(player, doodad)
		elseif doodad.CanSearch() and (doodadTemplate.dwCraftID ~= 0 and player.IsProfessionLearnedByCraftID(doodadTemplate.dwCraftID)) then
				OpenDoodad(player, doodad)
	  end
	  return true
	end

	if doodad.nKind == DOODAD_KIND.QUEST then
		if doodad.HaveQuest(dwPlayerID) then
			OpenDoodad(player, doodad)
        end
        return true
	end

	if doodad.nKind == DOODAD_KIND.CRAFT_TARGET then
		local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
		if doodadTemp and doodadTemp.dwCraftID ~= 0 and player.IsProfessionLearnedByCraftID(doodadTemp.dwCraftID) then
			OpenDoodad(player, doodad)
		end
		return true
	end

	if doodad.IsSelectable() then
		OpenDoodad(player, doodad)
	    return true
	end

	return true
end

function IsCorpseAndCanLoot(dwDoodadID)
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return false
	end

	return (doodad.nKind == DOODAD_KIND.CORPSE and doodad.CanLoot(g_pClientPlayer.dwID))
end

--[[
function NeedHightlightDoodad(dwDoodadID)
	--TODO:可能会根据技能，势力，自身状态之类的条件做
	return CanSelectDoodad(dwDoodadID)
end


function CanSelectDoodad(dwDoodadID)
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return false
	end

	if not doodad.IsSelectable() then
		return false
	end

	local player = GetClientPlayer()
	local dwPlayerID = player.dwID
	local bCorpse = doodad.nKind == DOODAD_KIND.CORPSE
	local bQuestDoodad = doodad.nKind == DOODAD_KIND.QUEST

	if bCorpse and not doodad.CanLoot(dwPlayerID) then
		return false
	elseif bQuestDoodad and not doodad.HaveQuest(dwPlayerID) then
		return false
	end

	return true
end

--根据doodad的类型显示不同的鼠标。
function ChangeCursorWhenOverDoodad(dwDoodadID)
	if IsCursorInExclusiveMode() then
		return
	end

	local player = GetClientPlayer()
	local dwPlayerID = player.dwID
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		Cursor.Switch(CURSOR.NORMAL)
		return
	end

	local bCan = doodad.CanDialog(player)
	if doodad.nKind == DOODAD_KIND.INVALID then
		Cursor.Switch(CURSOR.NORMAL)
	elseif doodad.nKind == DOODAD_KIND.NORMAL then
		Cursor.Switch(CURSOR.NORMAL)
	elseif doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
		if doodad.CanLoot(dwPlayerID) then
			if bCan then
				Cursor.Switch(CURSOR.LOOT)
			else
				Cursor.Switch(CURSOR.UNABLELOOT)
			end
		elseif doodad.CanSearch() then
			local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
			if doodadTemp and doodadTemp.dwCraftID == 3 and player.IsProfessionLearnedByCraftID(doodadTemp.dwCraftID) then --搜索
				if bCan then
					Cursor.Switch(CURSOR.SEARCH)
				else
					Cursor.Switch(CURSOR.UNABLESEARCH)
				end
			else
				Cursor.Switch(CURSOR.NORMAL)
			end
		end
	elseif doodad.nKind == DOODAD_KIND.QUEST then
		if doodad.HaveQuest(dwPlayerID) then
			if bCan then
				Cursor.Switch(CURSOR.QUEST)
			else
				Cursor.Switch(CURSOR.UNABLEQUEST)
			end
		else
			Cursor.Switch(CURSOR.NORMAL)
		end
	elseif doodad.nKind == DOODAD_KIND.READ then
		if bCan then
			Cursor.Switch(CURSOR.READ)
		else
			Cursor.Switch(CURSOR.UNABLEREAD)
		end
	elseif doodad.nKind == DOODAD_KIND.DIALOG then
		if bCan then
			Cursor.Switch(CURSOR.SPEAK)
		else
			Cursor.Switch(CURSOR.UNABLESPEAK)
		end
	elseif doodad.nKind == DOODAD_KIND.ACCEPT_QUEST then
		if bCan then
			Cursor.Switch(CURSOR.QUEST)
		else
			Cursor.Switch(CURSOR.UNABLEQUEST)
		end
	elseif doodad.nKind == DOODAD_KIND.TREASURE then
		if bCan then
			Cursor.Switch(CURSOR.LOCK)
		else
			Cursor.Switch(CURSOR.UNABLELOCK)
		end
	elseif doodad.nKind == DOODAD_KIND.ORNAMENT then
		Cursor.Switch(CURSOR.NORMAL)
	elseif doodad.nKind == DOODAD_KIND.CRAFT_TARGET then
		local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
		if doodadTemp and player.IsProfessionLearnedByCraftID(doodadTemp.dwCraftID) then
			if doodadTemp.dwCraftID == 1 then	--采矿
				if bCan then
					Cursor.Switch(CURSOR.MINE)
				else
					Cursor.Switch(CURSOR.UNABLEMINE)
				end
			elseif doodadTemp.dwCraftID == 2 then --采花
				if bCan then
					Cursor.Switch(CURSOR.FLOWER)
				else
					Cursor.Switch(CURSOR.UNABLEFLOWER)
				end
			elseif doodadTemp.dwCraftID == 3 then --庖丁
				if bCan then
					Cursor.Switch(CURSOR.SEARCH)
				else
					Cursor.Switch(CURSOR.UNABLESEARCH)
				end
			elseif doodadTemp.dwCraftID == 8 then --阅读
				if bCan then
					Cursor.Switch(CURSOR.READ)
				else
					Cursor.Switch(CURSOR.UNABLEREAD)
				end
			else
				Cursor.Switch(CURSOR.NORMAL)
			end
		else
			Cursor.Switch(CURSOR.NORMAL)
		end
	elseif doodad.nKind == DOODAD_KIND.CLIENT_ONLY then
		Cursor.Switch(CURSOR.NORMAL)
	elseif doodad.nKind == DOODAD_KIND.CHAIR and doodad.CanSit() then
		Cursor.Switch(CURSOR.QUEST)
	elseif doodad.nKind == DOODAD_KIND.DOOR then
		if not doodad.IsSelectable() then
			Cursor.Switch(CURSOR.NORMAL)
			return
		end

		if bCan then
			Cursor.Switch(CURSOR.LOCK)
		else
			Cursor.Switch(CURSOR.UNABLELOCK)
		end
	else
		Cursor.Switch(CURSOR.NORMAL)
	end
end

function NeedHighlightDoodadWhenOver(dwDoodadID)
	local dwPlayerID = GetClientPlayer().dwID
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return false
	end

	if doodad.nKind == DOODAD_KIND.INVALID then
		return false
	elseif doodad.nKind == DOODAD_KIND.NORMAL then
		return true
	elseif doodad.nKind == DOODAD_KIND.CORPSE then
		if doodad.CanLoot(dwPlayerID) then
			return true
		else
			local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
			if doodadTemp and doodadTemp.dwCraftID == 3 then --庖丁
				return true
			else
				return false
			end
		end
	elseif doodad.nKind == DOODAD_KIND.QUEST then
		if doodad.HaveQuest(dwPlayerID) then
			return true
		else
			return false
		end
	elseif doodad.nKind == DOODAD_KIND.READ then
		return true
	elseif doodad.nKind == DOODAD_KIND.DIALOG then
		return true
	elseif doodad.nKind == DOODAD_KIND.ACCEPT_QUEST then
		return true
	elseif doodad.nKind == DOODAD_KIND.TREASURE then
		return true
	elseif doodad.nKind == DOODAD_KIND.ORNAMENT then
		return true
	elseif doodad.nKind == DOODAD_KIND.CRAFT_TARGET then
		return true
	elseif doodad.nKind == DOODAD_KIND.CRAFT_TARGET then
		return true
	elseif doodad.nKind == DOODAD_KIND.GUIDE then
		return true
	elseif doodad.nKind == DOODAD_KIND.DOOR then
		if not doodad.IsSelectable() then
			return false
		end
		return true
	else
		return false
	end
	return false
end

function ShowDoodadBalloon(dwDoodadID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hDoodad = GetDoodad(dwDoodadID)
	if not hDoodad then
		return
	end

	local bQuestDoodad = hDoodad.nKind == DOODAD_KIND.QUEST
    if not bQuestDoodad then
        return
    end
	if not hDoodad.HaveQuest(hPlayer.dwID) then
	    return
	end

	if not hDoodad.IsSelectable() then
	    return
	end

    Doodad_ShowBalloon(dwDoodadID, true)
end

function ShowDoodadCraftBalloon(dwDoodadID)
    local hDoodad = GetDoodad(dwDoodadID)
	if not hDoodad then
		return
	end

    if hDoodad.nKind ~= DOODAD_KIND.CRAFT_TARGET then
        return
    end

    Doodad_ShowBalloon(dwDoodadID, true)
end

function HideDoodadBalloon(dwDoodadID)
    Doodad_ShowBalloon(dwDoodadID, false)
end
--]]