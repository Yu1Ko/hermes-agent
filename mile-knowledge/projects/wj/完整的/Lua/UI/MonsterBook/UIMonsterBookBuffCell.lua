local UIMonsterBookBuffCell = class("UIMonsterBookBuffCell")

function UIMonsterBookBuffCell:OnEnter(fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIMonsterBookBuffCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookBuffCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function ()
        self.fCallBack()
    end)
end

function UIMonsterBookBuffCell:RegEvent()

end

function UIMonsterBookBuffCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookBuffCell:UpdateInfo(tData)
    local bShut = not tData
    UIHelper.SetVisible(self.ImgShut, bShut)
    UIHelper.SetVisible(self.WidgetOpen, not bShut)

    if tData then
        local szName = UIHelper.GBKToUTF8(tData.szName)
        local szDescription = UIHelper.GBKToUTF8(tData.szDescription)
        local szImagePath = UIHelper.GetIconPathByIconID(tData.dwIconID)

        UIHelper.SetString(self.LabelName, szName)
        UIHelper.SetString(self.LabelContent, szDescription)
        UIHelper.SetTexture(self.ImgSkillIcon, szImagePath)
    end
end

return UIMonsterBookBuffCell