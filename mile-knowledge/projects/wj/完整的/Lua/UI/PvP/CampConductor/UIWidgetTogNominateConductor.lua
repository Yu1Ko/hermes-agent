-- ---------------------------------------------------------------------------------
-- Name: UIWidgetTogNominateConductor
-- Desc: 分配本周攻防指挥cell
-- Prefab:WidgetTogNominateConductor
-- ---------------------------------------------------------------------------------

local UIWidgetTogNominateConductor = class("UIWidgetTogNominateConductor")

function UIWidgetTogNominateConductor:_LuaBindList()
    self.LabeltConductorName    = self.LabeltConductorName -- 玩家名字
    self.LabeltConductorSlogan  = self.LabeltConductorSlogan -- 玩家口号
end

function UIWidgetTogNominateConductor:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
end

function UIWidgetTogNominateConductor:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTogNominateConductor:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fnCallBack then
            self.fnCallBack(self.nIndex)
        end
    end)
end

function UIWidgetTogNominateConductor:RegEvent()
    
end

function UIWidgetTogNominateConductor:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetTogNominateConductor:SetIndex(nIndex)
    self.nIndex = nIndex
end

function UIWidgetTogNominateConductor:SetEditState(bCanEdit)
    UIHelper.SetTouchEnabled(self._rootNode, bCanEdit)
    self.bCanEdit = bCanEdit
end

function UIWidgetTogNominateConductor:UpdateInfo(tInfo)
    if not tInfo then
        UIHelper.SetVisible(self.ImgPlayerIconEmpty, true)

        UIHelper.SetVisible(self.ImgPlayerIcon, false)
        UIHelper.SetVisible(self.AnimatePlayerIcon, false)
        UIHelper.SetVisible(self.SFXPlayerIcon, false)
        
        UIHelper.SetString(self.LabeltConductorName, "")
    else
        UIHelper.SetVisible(self.ImgPlayerIconEmpty, false)

        UIHelper.SetVisible(self.ImgPlayerIcon, true)
        UIHelper.SetVisible(self.AnimatePlayerIcon, true)
        UIHelper.SetVisible(self.SFXPlayerIcon, true)


        local hPlayer = GetPlayer(tInfo.dwID)
        if hPlayer then
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, hPlayer.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, hPlayer.nRoleType, hPlayer.dwForceID, true)
        else
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, 0, self.SFXPlayerIcon, self.AnimatePlayerIcon, nil, tInfo.nForceID, true)
        end

        UIHelper.SetString(self.LabeltConductorName, UIHelper.GBKToUTF8(tInfo.szName)) 
    end
end

function UIWidgetTogNominateConductor:SetClickCallBack(func)
    self.fnCallBack = func
end

function UIWidgetTogNominateConductor:SetSelectedRaw(bSelected)
    UIHelper.SetSelected(self._rootNode, bSelected, false)
end

return UIWidgetTogNominateConductor