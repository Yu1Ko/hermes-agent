local UIRestScreenView = class("UIRestScreenView")

function UIRestScreenView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIRestScreenView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRestScreenView:BindUIEvent()

end

function UIRestScreenView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

end

function UIRestScreenView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRestScreenView:UpdateInfo()
    local szBgPath = "Texture/LoadingMap/ShengDianMoShi.png" -- 省电模式背景图路径
    UIHelper.SetTexture(self.ImgBg, szBgPath, true)
end

return UIRestScreenView