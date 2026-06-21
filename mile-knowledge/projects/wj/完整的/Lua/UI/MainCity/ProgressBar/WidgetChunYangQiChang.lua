-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: WidgetChunYangQiChang
-- Date: 2025-10-29 15:26:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local WidgetChunYangQiChang = class("WidgetChunYangQiChang")

function WidgetChunYangQiChang:OnEnter(nIndex)
    self.nIndex = nIndex
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function WidgetChunYangQiChang:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function WidgetChunYangQiChang:BindUIEvent()
end

function WidgetChunYangQiChang:RegEvent()
end

function WidgetChunYangQiChang:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetChunYangQiChang:UpdateQiChangInfo(tGasInfo)
    if tGasInfo then
        self.dwTemplateID = tGasInfo.dwTemplateID
        self.nEndTime = tGasInfo.nEndTime
        self.tGasInfo = tGasInfo
        local szPath = TabHelper.GetSkillIconPathByIDAndLevel(tGasInfo.dwSkillID, 1)
        UIHelper.SetTexture(self.ImgSkillIcon, szPath)
        self:UpdateQiChangTime()
    else
        LOG.ERROR("View.UpdateGasMod: tGasInfo is nil, dwNPCID = %d, dwTemplateID = %d")
    end
end

function WidgetChunYangQiChang:UpdateQiChangTime()
    local fnUpdate = function()
        if self.nEndTime then
            local nLeftTime = self.nEndTime - GetGSCurrentTime()
            if nLeftTime > 0 then
                UIHelper.SetLabel(self.LabelCount, nLeftTime)
            else
                self.tGasInfo.nEndTime = nil
                Event.Dispatch("OnUpdateCYGas", self.tGasInfo)
            end
        end
    end
    fnUpdate()
    Timer.DelAllTimer(self)
    Timer.AddCycle(self, 1 / 8, fnUpdate)
end

return WidgetChunYangQiChang