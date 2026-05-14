-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent14
-- Date: 2024-07-08 14:46:48
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIItemTipContent14 = class("UIItemTipContent14")

function UIItemTipContent14:OnEnter(szText, fCallBack)
    if not szText then return end
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szText = szText
    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIItemTipContent14:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipContent14:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function ()
        if self.fCallBack then
            self.fCallBack()
        end
    end)
end

function UIItemTipContent14:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent14:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIItemTipContent14:UpdateInfo()
    UIHelper.SetRichText(self.RichTextContent, self.szText)
    UIHelper.LayoutDoLayout(self._rootNode)
    UIHelper.SetTouchDownHideTips(self.BtnTrace, false)
end

function UIItemTipContent14:SetBtnVisible(bVisible)
    UIHelper.SetVisible(self.BtnTrace, bVisible)
end


return UIItemTipContent14