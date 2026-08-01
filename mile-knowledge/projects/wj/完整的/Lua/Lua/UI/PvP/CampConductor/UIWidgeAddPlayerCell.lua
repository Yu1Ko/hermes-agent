-- ---------------------------------------------------------------------------------
-- Name: UIWidgeAddPlayerCell
-- Desc: 添加玩家cell
-- Prefab:WidgeAddCrewPlayerCell
-- ---------------------------------------------------------------------------------

local UIWidgeAddPlayerCell = class("UIWidgeAddPlayerCell")

function UIWidgeAddPlayerCell:OnEnter(tbPlayerInfo)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.tbPlayerInfo = tbPlayerInfo
    self:UpdateInfo()
end

function UIWidgeAddPlayerCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgeAddPlayerCell:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgeCrewPlayerInfo, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:ShowPlayerInfo()
        end
    end)
end

function UIWidgeAddPlayerCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetSelected(self.WidgeCrewPlayerInfo, false, false)
    end)
end

function UIWidgeAddPlayerCell:UnRegEvent()

end



function UIWidgeAddPlayerCell:ShowPlayerInfo()
    local tbButton = self:GetButtonList()
    local nPlayerID = self.tbPlayerInfo.id
    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPlayerPop, self.WidgeCrewPlayerInfo, TipsLayoutDir.RIGHT_CENTER, nPlayerID, tbButton)
    script:ShowCommandAddMemberInfo(self.tbPlayerInfo)
end

function UIWidgeAddPlayerCell:GetButtonList()
    local szName = UIHelper.GBKToUTF8(self.tbPlayerInfo.szName)
    local tbButton = 
    {
        {
            szName = "密聊",
            bCloseOnClick = true,
            callback = function()
                local tbData = {szName = szName, dwTalkerID = self.tbPlayerInfo.id, dwForceID = self.tbPlayerInfo.nForceID}
                ChatHelper.WhisperTo(szName, tbData)
            end
        },
        {
            szName = g_tStrings.STR_COMMAND_MODIFY_PRIORITY1,
            bCloseOnClick = true,
            callback = function()
                -- RemoteCallToServer("On_Camp_GFModifyRights", self.tbPlayerInfo.id, 1)
                RemoteCallToServer("On_Camp_GFAddMember", 1, {{self.tbPlayerInfo.id, 1, self.tbPlayerInfo.szName}})
            end
        },

        {
            szName = g_tStrings.STR_COMMAND_MODIFY_PRIORITY2,
            bCloseOnClick = true,
            callback = function()
                -- RemoteCallToServer("On_Camp_GFModifyRights", self.tbPlayerInfo.id, 2)
                RemoteCallToServer("On_Camp_GFAddMember", 1, {{self.tbPlayerInfo.id, 2, self.tbPlayerInfo.szName}})
            end
        },

        {
            szName = g_tStrings.STR_COMMAND_MODIFY_PRIORITY3,
            bCloseOnClick = true,
            callback = function()
                -- RemoteCallToServer("On_Camp_GFModifyRights", self.tbPlayerInfo.id, 3)
                RemoteCallToServer("On_Camp_GFAddMember", 1, {{self.tbPlayerInfo.id, 3, self.tbPlayerInfo.szName}})
            end
        },
    }

    return tbButton

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgeAddPlayerCell:UpdateInfo()
    local tbPlayerInfo = self.tbPlayerInfo
    local szName = tbPlayerInfo.szName
    UIHelper.SetString(self.LableName, UIHelper.GBKToUTF8(szName))

    UIHelper.RemoveAllChildren(self.WidgetPlayerHead)
    self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetPlayerHead, tbPlayerInfo.id)
    self.scriptHead:SetHeadInfo(tbPlayerInfo.id, 0, nil, tbPlayerInfo.nForceID)

    UIHelper.SetString(self.LableLevel, tbPlayerInfo.nLevel)

    UIHelper.SetVisible(self.LableGroupTitle, false)
    UIHelper.SetVisible(self.LableGroup, false)

end

return UIWidgeAddPlayerCell