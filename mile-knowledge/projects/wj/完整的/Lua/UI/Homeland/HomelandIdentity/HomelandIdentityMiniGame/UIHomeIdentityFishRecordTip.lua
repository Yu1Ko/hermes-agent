-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishRecordTip
-- Date: 2024-02-04 11:41:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityFishRecordTip = class("UIHomeIdentityFishRecordTip")

function UIHomeIdentityFishRecordTip:OnEnter(tHolder)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tHolder = tHolder
    self:UpdateInfo()
end

function UIHomeIdentityFishRecordTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishRecordTip:BindUIEvent()
    
end

function UIHomeIdentityFishRecordTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeIdentityFishRecordTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function GetFishInfo(dwID)
    local tFishInfo = Table_GetAllFishInfo()
    for _, v in pairs(tFishInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

function UIHomeIdentityFishRecordTip:UpdateInfo()
    local tHolder = self.tHolder
    local tInfo    = GetFishInfo(tHolder.nFishIndex)
    local szWeight = FormatString(g_tStrings.STR_HOMELAND_FISHWEIGHT, string.format("%.2f",(tHolder.nRecord / 100)))
    local szPlayerName = UIHelper.GBKToUTF8(tHolder.szName)
    local szFishName = UIHelper.GBKToUTF8(tInfo.szName)

    UIHelper.SetString(self.LabelTop, string.format("%s：%s", szFishName, szWeight))
    UIHelper.SetString(self.LabelName, string.format("%s", szPlayerName))
end


return UIHomeIdentityFishRecordTip