-- ---------------------------------------------------------------------------------
-- Name: UIWidgePlayerCell
-- Desc: 核心玩家cell
-- Prefab:WidgeCrewPlayerCell
-- ---------------------------------------------------------------------------------
local MEMBER_TYPE_IMAGE = {
    [1] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_fuguan",
    [2] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_diaoduguan",
    [3] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_fuzhihui",
    [4] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_zhuzhihui",
}

local UIWidgePlayerCell = class("UIWidgePlayerCell")

function UIWidgePlayerCell:OnEnter(tbPlayerInfo, bRemove)
    self.bRemove = bRemove
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    if tbPlayerInfo then 
        self.tbPlayerInfo = tbPlayerInfo
        self:UpdateInfo()
    end
end

function UIWidgePlayerCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgePlayerCell:BindUIEvent()
    if not self.bRemove then
        UIHelper.BindUIEvent(self.WidgeCrewPlayerInfo, EventType.OnSelectChanged, function(_, bSelect)
            if bSelect then
                self:ShowPlayerInfo()
            end
        end)
    end
    if self.bRemove and self.TogSelect then
        UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function(_, bSelect)
            if bSelect then
                Event.Dispatch(EventType.AddMemberToRemoveList, self.tbPlayerInfo.tNumberInfo.dwDeputyID)
            else
                Event.Dispatch(EventType.RemoveMemberFromRemoveList, self.tbPlayerInfo.tNumberInfo.dwDeputyID)
            end
        end)
    end
end

function UIWidgePlayerCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetSelected(self.WidgeCrewPlayerInfo, false, false)
    end)

    -- Event.Reg(self, "On_CAMP_PLAYER_LOGIN", function()--人员登陆后会刷列表，看起来此事件并不需要
    --     local bOnline, dwID = arg0, arg1
    --     local tbNumberInfo = self.tbPlayerInfo.tNumberInfo
    --     local nPlayerID = tbNumberInfo.dwDeputyID
    --     if nPlayerID == dwID then
    --         UIHelper.SetSpriteFrame(self.ImgOnline, FRIEND_ONLINE_STATE[bOnline and 1 or 0])
    --     end
    -- end)
end

function UIWidgePlayerCell:UnRegEvent()

end


function UIWidgePlayerCell:ShowPlayerInfo()
    local tbButton = self:GetButtonList()
    local nPlayerID = self.tbPlayerInfo.tNumberInfo.dwDeputyID
    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPlayerPop, self.WidgeCrewPlayerInfo, TipsLayoutDir.LEFT_CENTER, nPlayerID, tbButton)
    script:ShowCommandMemberInfo(self.tbPlayerInfo.tStringInfo)
end

function UIWidgePlayerCell:GetButtonList()
    local szName = UIHelper.GBKToUTF8(self.tbPlayerInfo.tStringInfo.szName)
    local tbButton = 
    {
        {
            szName = "密聊",
            bCloseOnClick = true,
            callback = function()
                local dwTalkerID = self.tbPlayerInfo.tNumberInfo.dwDeputyID
                local nForceID = self.tbPlayerInfo.tStringInfo.nForceID
                local tbData = {szName = szName, dwTalkerID = self.tbPlayerInfo.tNumberInfo.dwDeputyID, dwForceID = nForceID}
                ChatHelper.WhisperTo(szName, tbData)
            end
        },

        {
            szName = "组队",
            bCloseOnClick = true,
            callback = function()
                GetClientTeam().InviteJoinTeam(UTF8ToGBK(szName))
            end,
            fnDisable = function()
                return not TeamData.CanMakeParty()
            end
        }
    }

    local tbCommanderButton = 
    {
        {
            szName = g_tStrings.STR_COMMAND_MODIFY_PRIORITY1,
            bCloseOnClick = true,
            callback = function()
                RemoteCallToServer("On_Camp_GFModifyRights", self.tbPlayerInfo.tNumberInfo.dwDeputyID, 1)
            end
        },

        {
            szName = g_tStrings.STR_COMMAND_MODIFY_PRIORITY2,
            bCloseOnClick = true,
            callback = function()
                RemoteCallToServer("On_Camp_GFModifyRights", self.tbPlayerInfo.tNumberInfo.dwDeputyID, 2)
            end
        },

        {
            szName = g_tStrings.STR_COMMAND_MODIFY_PRIORITY3,
            bCloseOnClick = true,
            callback = function()
                RemoteCallToServer("On_Camp_GFModifyRights", self.tbPlayerInfo.tNumberInfo.dwDeputyID, 3)
            end
        },

        {
            szName = g_tStrings.STR_COMMAND_REMOVE,
            bCloseOnClick = true,
            callback = function()
                RemoteCallToServer("On_Camp_GFDelMember", self.tbPlayerInfo.tNumberInfo.dwDeputyID)
            end
        }
    }


    if CommandBaseData.GetRoleType() == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
        table.insert_tab(tbButton, tbCommanderButton)
    end

    return tbButton

end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgePlayerCell:UpdateInfo()
    local tbNumberInfo = self.tbPlayerInfo.tNumberInfo
    local tbStringInfo = self.tbPlayerInfo.tStringInfo

    local szPlayerName = UIHelper.GBKToUTF8(tbStringInfo.szName)
    local nLevel = tbStringInfo.nLevel or 130
    UIHelper.SetString(self.LableName, szPlayerName, 7)
    UIHelper.LayoutDoLayout(self.LayoutName)
    UIHelper.SetString(self.LableLevel, tostring(nLevel))

    for nIndex = 1, 4 do
        local nNum = tbNumberInfo["DeputyInfo"][nIndex]
        UIHelper.SetString(self.tbLabelShenji[nIndex], nNum)
    end

    local szGangName = tbStringInfo.szTName ~= '' and UIHelper.GBKToUTF8(tbStringInfo.szTName) or g_tStrings.STR_COMMAND_NOGANG
    UIHelper.SetString(self.LableGroup, szGangName)

    local nMemberType = tbNumberInfo["DeputyInfo"][0]
    local szMemberType = ""
    if nMemberType == 1 then
        szMemberType = "辅官"
    elseif nMemberType == 2 then
        szMemberType = "调度官"
    elseif nMemberType == 3 then
        szMemberType = "副指挥"
    elseif nMemberType == 4 then
        szMemberType = "主指挥"
    end

    UIHelper.SetString(self.LablePlayerStatus, szMemberType)
    UIHelper.SetSpriteFrame(self.ImgStatus, MEMBER_TYPE_IMAGE[nMemberType])

    UIHelper.RemoveAllChildren(self.WidgetPlayerHead)
    self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetPlayerHead, tbNumberInfo.dwDeputyID)
    self.scriptHead:SetHeadInfo(tbNumberInfo.dwDeputyID, 0, nil, tbStringInfo.nForceID)

    UIHelper.SetSpriteFrame(self.ImgOnline, FRIEND_ONLINE_STATE[tbNumberInfo["DeputyInfo"][5]])

    if not self.bRemove then
        UIHelper.SetToggleGroupIndex(self.WidgeCrewPlayerInfo, ToggleGroupIndex.MonsterBookSkillBook)
        UIHelper.SetSelected(self.WidgeCrewPlayerInfo, false, false)
    else
        UIHelper.SetSelected(self.TogSelect, false, false)
    end

end



return UIWidgePlayerCell