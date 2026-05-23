-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieHSLSetting
-- Date: 2025-03-05 11:24:28
-- Desc: HSL设置面板
-- ---------------------------------------------------------------------------------

local UISelfieHSLSetting = class("UISelfieHSLSetting")

function UISelfieHSLSetting:OnEnter(tColorSetting, onSelectedCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not tColorSetting then
        return
    end
    self.onSelectedCallback = onSelectedCallback
    self:UpdateInfo(tColorSetting)
end

function UISelfieHSLSetting:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieHSLSetting:BindUIEvent()
    for i, v in ipairs(self.tbToggleColor) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
			self:UpdateSelectIndex(i)
        end)
    end
end

function UISelfieHSLSetting:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieHSLSetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieHSLSetting:UpdateInfo(tColorSetting)
    self.nCurSelectedIndex = -1
    self.tColorIDs = {}
    for _, tColor in ipairs(tColorSetting) do
        table.insert(self.tColorIDs, tColor.nColorID)
    end
end

function UISelfieHSLSetting:SearchColorID(nColorID)
    for k, nId in ipairs(self.tColorIDs) do
        if nColorID == nId then
            self:UpdateSelectIndex(k)
            break
        end
    end
end

function UISelfieHSLSetting:UpdateSelectIndex(nIndex)
    if self.nCurSelectedIndex  == nIndex then
        return
    end
    if self.tbToggleSelected[self.nCurSelectedIndex] then
        UIHelper.SetVisible(self.tbToggleSelected[self.nCurSelectedIndex],false)
    end
    self.nCurSelectedIndex = nIndex
    UIHelper.SetVisible(self.tbToggleSelected[nIndex],true)
    if self.onSelectedCallback then
        self.onSelectedCallback(self.tColorIDs[nIndex])
    end
end

function UISelfieHSLSetting:SetEnableState(bEnable)
    for i, v in ipairs(self.tbToggleColor) do
        UIHelper.SetEnable(v, bEnable)
    end
end

return UISelfieHSLSetting