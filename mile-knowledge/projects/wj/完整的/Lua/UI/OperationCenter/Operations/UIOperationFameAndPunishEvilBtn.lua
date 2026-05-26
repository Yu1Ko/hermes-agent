-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationFameAndPunishEvilBtn
-- Date: 2026-04-14 09:59:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationFameAndPunishEvilBtn = class("UIOperationFameAndPunishEvilBtn")

function UIOperationFameAndPunishEvilBtn:OnEnter(fnCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fnCallback = fnCallback
    self:UpdateInfo()
end

function UIOperationFameAndPunishEvilBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationFameAndPunishEvilBtn:BindUIEvent()
    for nIndex, btn in ipairs(self.tButton) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            self.fnCallback(nIndex)
        end)
    end
end

function UIOperationFameAndPunishEvilBtn:RegEvent()
    Event.Reg(self, EventType.OnOperationSelectFameBtn, function(nSelectIndex)
        for nIndex, btn in ipairs(self.tButton) do
            local imgSelect = UIHelper.GetChildByName(btn, "ImgSelect")
            UIHelper.SetVisible(imgSelect, nIndex == nSelectIndex)
        end
    end)
end

function UIOperationFameAndPunishEvilBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationFameAndPunishEvilBtn:UpdateInfo()
    local tInfo = Table_GetFameAndPunishEvilInfo()[1]
    UIHelper.SetString(self.LabelName1, UIHelper.GBKToUTF8(tInfo.szSubTab1))
    UIHelper.SetString(self.LabelName2, UIHelper.GBKToUTF8(tInfo.szSubTab2))
end


return UIOperationFameAndPunishEvilBtn