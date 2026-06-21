-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIPageBg
-- Date: 2024-06-04 23:10:33
-- Desc: Page 的Bg 临时遮挡用
-- ---------------------------------------------------------------------------------

local UIPageBg = class("UIPageBg")

function UIPageBg:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetVisible(self.ImgBg, false)

    self.nViewID = nil
    local scriptParent = UIHelper.GetBindScript(self.parent)
    if scriptParent then
        self.nViewID = scriptParent._nViewID
    end
end

function UIPageBg:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPageBg:BindUIEvent()

end

function UIPageBg:RegEvent()
    Event.Reg(self, EventType.AfterCaptureScreen, function(nViewID)
        if self.nViewID == nViewID then return end

        Timer.DelTimer(self, self.nHideTimerID)

        UIHelper.SetVisible(self.ImgBg, true)

        if not self.bHasSetSprite then
            UIHelper.SetSpriteFrame(self.ImgBg, "UIAtlas2_Public_PublicPanel_PublicPanel3_BG_Translucent2520x2520", nil, false)
            self.bHasSetSprite = true
        end

        self.nHideTimerID = Timer.Add(self, 0.15, function()
            UIHelper.SetVisible(self.ImgBg, false)
        end)
    end)
end

function UIPageBg:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPageBg:UpdateInfo()

end


return UIPageBg