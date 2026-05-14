-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCountDown
-- Date: 2022-12-08 11:40:36
-- Desc: 倒计时界面 WidgetCountDown
-- ---------------------------------------------------------------------------------

---@class UIWidgetCountDown
local UIWidgetCountDown = class("UIWidgetCountDown")

function UIWidgetCountDown:OnEnter(nCountDown, bShowStart)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        if nCountDown then
            self:PlayCountDown(nCountDown, bShowStart)
        end
    end
end

function UIWidgetCountDown:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:StopCountDown()
end

function UIWidgetCountDown:BindUIEvent()
    
end

function UIWidgetCountDown:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCountDown:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetCountDown:PlayCountDown(nCountDown, bShowStart)
    if not nCountDown then return end
    if bShowStart == nil then
        bShowStart = true
    end

    self:StopCountDown()
    nCountDown = math.floor(nCountDown + 0.5) --四舍五入

    if nCountDown > 0 then
        self:UpdateCountDown(nCountDown)

        Timer.AddCountDown(self, nCountDown, 
        function()
            nCountDown = nCountDown - 1
            self:UpdateCountDown(nCountDown, nil, bShowStart)
        end)
    else
        self:OnCountDownEnd(bShowStart)
    end
end

function UIWidgetCountDown:StopCountDown()
    Timer.DelAllTimer(self)
    UIHelper.StopAllAni(self)
    UIHelper.SetVisible(self.WidgetAniCountDown, false)
    UIHelper.SetVisible(self.WidgetAniStart, false)
end

function UIWidgetCountDown:UpdateCountDown(nCountDown, bShowTitle, bShowStart)
    if nCountDown <= 0 then
        self:OnCountDownEnd(bShowStart)
        return
    end

    if bShowTitle == nil then
        --剩余时间大于等于10s会显示“倒计时”的title
        bShowTitle = nCountDown >= 10
    end
    UIHelper.SetVisible(self.ImgCountDown, bShowTitle)

    UIHelper.SetVisible(self.WidgetAniCountDown, true)
    UIHelper.SetVisible(self.WidgetAniStart, false)
    UIHelper.SetString(self.LabelCountDown, string.format("%d", nCountDown))
    UIHelper.PlayAni(self, self.WidgetAniCountDown, "AniCountDown1", function()
        --有时动画结束回调会有延迟，加个判断
        if UIHelper.GetString(self.LabelCountDown) == tostring(nCountDown) then
            UIHelper.SetVisible(self.WidgetAniCountDown, false)
        end
    end)
end

function UIWidgetCountDown:PlayStartAnim()
    UIHelper.SetVisible(self.WidgetAniCountDown, false)
    UIHelper.SetVisible(self.WidgetAniStart, true)
    UIHelper.PlayAni(self, self.WidgetAniStart, "AniStart", function()
        UIHelper.SetVisible(self.WidgetAniStart, false)
    end)
end

function UIWidgetCountDown:OnCountDownEnd(bShowStart)
    if bShowStart then
        self:PlayStartAnim()
    else
        UIHelper.SetVisible(self.WidgetAniCountDown, false)
        UIHelper.SetVisible(self.WidgetAniStart, false)
    end
end

return UIWidgetCountDown