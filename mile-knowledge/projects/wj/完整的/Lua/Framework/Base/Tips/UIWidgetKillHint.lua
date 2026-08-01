-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetNormalHintCell
-- Date: 2023-11-30 09:55:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetKillHint = class("UIWidgetKillHint")

function UIWidgetKillHint:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetKillHint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetKillHint:BindUIEvent()

end

function UIWidgetKillHint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetKillHint:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function OnUpdateTextPos(self, xScreen, yScreen, x, y, z)
    --local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
    --xScreen, yScreen = xScreen / nScaleX, yScreen / nScaleY
    --local tPos = cc.Director:getInstance():convertToGL({x = xScreen, y = yScreen})
    --local widget = self._rootNode:getParent()
    local nX, nY = 0,0
    --local anchor = widget:getAnchorPointInPoints()

    local randomX = math.random(-6, 6)
    local randomY = math.random(-6, 6)

    --local randomX = 0
    --local randomY = 0

    print(nX + randomX, nY + randomY)
    UIHelper.SetPosition(self._rootNode, nX + randomX, nY + randomY)
    UIHelper.SetVisible(self._rootNode, true)
    
    local szClip = self:fnGetClipName()
    self.bIsPlaying = true
    UIHelper.PlayAni(self, self.WidgetAni, szClip, function()
        print("finished las")
        self.bIsPlaying = false
        UIHelper.SetVisible(self._rootNode, false)

        if IsFunction(self.fnCallback) then
            self.fnCallback()
        end
    end)
end

function UIWidgetKillHint:ShowKillHint(szName, fnCallback)
    self.fnCallback = fnCallback
    UIHelper.SetString(self.LabelSkillName, "击伤·" .. szName)    --end)

    PostThreadCall(OnUpdateTextPos, self, "Scene_GetCharacterSkillEffectTextPos")
end

function UIWidgetKillHint:fnGetClipName()
    return "AniKillNormalHint"
end

return UIWidgetKillHint