-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomAvatarContent
-- Date: 2022-12-19 13:45:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomAvatarContent = class("UICustomAvatarContent")

-- local AvatarName = {
--     [1] = "·一",
--     [2] = "·二",
--     [3] = "·三",
--     [4] = "·四",
--     [5] = "·五",
--     [6] = "·六",
-- }

function UICustomAvatarContent:OnEnter(dwID,tLine,bSchool,index)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwID = dwID
    self.tLine = tLine

    if not self.dwID then
        return
    end
    --self.tImage = g_tTable.RoleAvatar:Search(dwID)
    self:UpdateInfo(bSchool,index)
end

function UICustomAvatarContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICustomAvatarContent:BindUIEvent()
    UIHelper.BindUIEvent(self.TogChoose,EventType.OnSelectChanged,function (_,bSelected)
        if bSelected then
            Event.Dispatch(EventType.PreviewAvator,self.dwID,g_pClientPlayer.dwID)
        end
    end)
end

function UICustomAvatarContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.PreviewAvator, function (dwID)
        if self.dwID ~= dwID and UIHelper.GetSelected(self.TogChoose) then
            UIHelper.SetSelected(self.TogChoose,false)
        end
    end)
    Event.Reg(self, "SET_MINI_AVATAR", function (dwID)
        if self.dwID ~= dwID then
            self:SetEquipmentState(false)
        else
            self:SetEquipmentState(true)
        end
    end)
end

function UICustomAvatarContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICustomAvatarContent:UpdateInfo(bSchool,index)
    --玩家已装备
    if g_pClientPlayer.dwMiniAvatarID == self.dwID then
        self:SetEquipmentState(true)
        UIHelper.SetSelected(self.TogChoose,true)
    else
        self:SetEquipmentState(false)
    end

    self:UpdateAvatar()
    local line = UIAvatarNameTab[self.dwID]
    if not line and bSchool then
        UIHelper.SetString(self.LabelContent,"门派头像")
    elseif not line and not bSchool then
        UIHelper.SetString(self.LabelContent,"江湖头像")
    else
        UIHelper.SetString(self.LabelContent,line.Name)
    end
end

function UICustomAvatarContent:UpdateAvatar()
    UIHelper.RoleChange_UpdateAvatar(self.ImgPlayer,self.dwID,self.SFXPlayerIcon,self.AnimatePlayer, nil, nil, true, false, nil, false)
    UIHelper.UpdateAvatarFarme(self.tbImgFrameNormalBg,self.dwID,self.SFXFrameBgAll,self.SFXFrameBg1,self.SFXFrameBg3)
    UIHelper.SetNodeSwallowTouches(self.WidgetMainCityPlayer, false, true)
    UIHelper.SetNodeSwallowTouches(self.WidgetPlayerNormal, false, true)
    UIHelper.SetNodeSwallowTouches(self.BtnCharacter, false, true)
end

function UICustomAvatarContent:SetEquipmentState(bEquipment)
    UIHelper.SetVisible(self.ImgEquipment,bEquipment)
end

function UICustomAvatarContent:OnlyShow()
    UIHelper.SetVisible(self.LabelContent,false)
    UIHelper.SetVisible(self.ImgEquipment,false)
    UIHelper.SetVisible(self.TogChoose,false)
end

return UICustomAvatarContent