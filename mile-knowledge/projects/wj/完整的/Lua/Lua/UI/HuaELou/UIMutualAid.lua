-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMutualAid
-- Date: 2023-08-31 15:34:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMutualAid = class("UIMutualAid")

function UIMutualAid:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    self.dwOperatActID = dwOperatActID

    local tLine = Table_GetOperActyInfo(self.dwOperatActID)
    if tLine then
        local tStartTime, tEndTime = tLine.tStartTime, tLine.tEndTime
        local nStart = tStartTime[1]
        local nEnd = tEndTime and tEndTime[1]
        local szText = HuaELouData.GetTimeShowText(nStart, nEnd)

        UIHelper.SetString(self.LabelMiddle, szText)
    end
end

function UIMutualAid:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMutualAid:BindUIEvent()
    UIHelper.BindUIEvent()
end

function UIMutualAid:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMutualAid:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMutualAid:UpdateInfo()

end


return UIMutualAid