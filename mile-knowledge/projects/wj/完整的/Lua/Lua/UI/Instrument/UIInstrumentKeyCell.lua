-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentKeyCell
-- Date: 2025-07-08 10:14:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInstrumentKeyCell = class("UIInstrumentKeyCell")

function UIInstrumentKeyCell:OnEnter(nTone, nIndex, szName, szKey)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nTone = nTone
    self.nIndex = nIndex
    UIHelper.SetString(self.LabelMusicTitle, szName)
    if Platform.IsWindows() then
        UIHelper.SetVisible(self.LabelMusicKeys, true)
        UIHelper.SetString(self.LabelMusicKeys, szKey)
    end
end

function UIInstrumentKeyCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentKeyCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnKey, true)
    UIHelper.SetTouchDownHideTips(self.BtnKey, false)

end

function UIInstrumentKeyCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.ImgBtnBg_Up, false)
        local eff = UIHelper.GetChildByName(self.ImgBtnBg_Up, "Eff_演奏长按01")
        if eff then
            UIHelper.SetVisible(eff, false)
        end
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function ()
        UIHelper.SetVisible(self.ImgBtnBg_Up, false)
        local eff = UIHelper.GetChildByName(self.ImgBtnBg_Up, "Eff_演奏长按01")
        if eff then
            UIHelper.SetVisible(eff, false)
        end
    end)

    Event.Reg(self, EventType.OnPressInstrumentKey, function (nTone, nIndex, bDown)
        if self.nTone == nTone and self.nIndex == nIndex then
            UIHelper.SetVisible(self.ImgBtnBg_Up, bDown)
            local eff = UIHelper.GetChildByName(self.ImgBtnBg_Up, "Eff_演奏长按01")
            if eff then
                UIHelper.SetVisible(eff, bDown)
            end
        end
    end)
end

function UIInstrumentKeyCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentKeyCell:UpdateInfo()
    
end

function UIInstrumentKeyCell:SetClickCallback(fnCallBack)
    self.fnCallBack = fnCallBack
end

return UIInstrumentKeyCell