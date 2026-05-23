local UIAccountBindingRoleCell = class("UIAccountBindingRoleCell")

function UIAccountBindingRoleCell:OnEnter(tPlayerSource)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.tPlayerSource = tPlayerSource        
    end

    self:UpdateInfo()
end

function UIAccountBindingRoleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAccountBindingRoleCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAddBinding, EventType.OnClick, function()
        self:ShowBindTip()
    end)

    UIHelper.BindUIEvent(self.BtnHead, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetAccountsBindingRoleTips, self._rootNode, self.tPlayerSource)
    end)
end

function UIAccountBindingRoleCell:RegEvent()
  
end

function UIAccountBindingRoleCell:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAccountBindingRoleCell:UpdateInfo()
    local bIsCurrentPlayer = false
    
    if self.tPlayerSource then
        local tPlayerSource = self.tPlayerSource
        bIsCurrentPlayer = tPlayerSource.dwRoleID == g_pClientPlayer.dwID
        tPlayerSource.dwForceID = tPlayerSource.nForceID --逻辑给的nForceID，其他头像相关使用的是dwForceID
        local dwMiniAvatarID = Table_GetMiniAvatarID(tPlayerSource.dwForceID).dwMiniAvatarID
        UIHelper.RoleChange_UpdateAvatar(self.ImgIcon, dwMiniAvatarID, nil, nil,tPlayerSource.nRoleType, tPlayerSource.dwForceID, true)
    end

    UIHelper.SetVisible(self.BtnAddBinding, not self.tPlayerSource)
    UIHelper.SetVisible(self.BtnHead, self.tPlayerSource ~= nil)
    UIHelper.SetVisible(self.ImgPolishCountBG, bIsCurrentPlayer)
end

function UIAccountBindingRoleCell:ShowBindTip()
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    if pPlayer.bAccountShared then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_BIND_PLAYER)
    else
        local szMsg = FormatString(g_tStrings.ASP_BINDPLAYER_SURE, UIHelper.GBKToUTF8(pPlayer.szName))
        local fnBindPlayer = function()
            local pPlayer = g_pClientPlayer
            local nRecode = pPlayer.AddSelfToAccountShared()
            if nRecode then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_BIND_SUCCEED)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_BIND_FAILED)
            end
        end
        UIHelper.ShowConfirm(szMsg, fnBindPlayer)
    end
end

return UIAccountBindingRoleCell