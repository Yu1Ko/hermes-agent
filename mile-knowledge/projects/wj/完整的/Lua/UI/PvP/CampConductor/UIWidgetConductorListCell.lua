-- ---------------------------------------------------------------------------------
-- Name: UIWidgetConductorListCell
-- Desc: 分配本周攻防指挥页面——右侧分配页面cell
-- Prefab:WidgetConductorListCell
-- ---------------------------------------------------------------------------------

local UIWidgetConductorListCell = class("UIWidgetConductorListCell")

function UIWidgetConductorListCell:_LuaBindList()
    self.LabelName     = self.LabelName -- 玩家名字
end

function UIWidgetConductorListCell:OnEnter(dwID, tInfo, func)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.dwID = dwID
    self.fnCallBack = func
    self:UpdateInfo(tInfo)
    UIHelper.SetTouchDownHideTips(self._rootNode, false)
end

function UIWidgetConductorListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetConductorListCell:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fnCallBack then
            self.fnCallBack(self.dwID)
        end
    end)
end

function UIWidgetConductorListCell:RegEvent()
    
end

function UIWidgetConductorListCell:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetConductorListCell:UpdateInfo(tInfo)
    UIHelper.SetString(self.LabeltConductorName, UIHelper.GBKToUTF8(tInfo.szName))
    
    local hPlayer = GetPlayer(tInfo.dwID)
    if hPlayer then
        UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, hPlayer.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, hPlayer.nRoleType, hPlayer.dwForceID, true)
    else
        UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, 0, self.SFXPlayerIcon, self.AnimatePlayerIcon, nil, tInfo.nForceID, true)
    end
end

return UIWidgetConductorListCell