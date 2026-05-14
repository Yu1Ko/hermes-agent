-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTangMenMonitor
-- Date: 2025-09-01 15:45:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTangMenMonitor = class("UIWidgetTangMenMonitor")
local KONGFU_ID = 10

function UIWidgetTangMenMonitor:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetTangMenMonitor:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetTangMenMonitor:BindUIEvent()
    
end

function UIWidgetTangMenMonitor:RegEvent()
    Event.Reg(self, "SkillCDJingYuJue_Open", function ()
        UIHelper.SetVisible(self._rootNode, true)
        if self.nTimer then
            Timer.DelTimer(self, self.nTimer)
            self.nTimer = nil
        end
        self.nTimer = Timer.AddCycle(self, 0.1, function ()
            self:UpdateData()
            self:UpdateInfo()
        end)
    end)

    Event.Reg(self, "SkillCDJingYuJue_Close", function ()
        UIHelper.SetVisible(self._rootNode, false)
        Timer.DelAllTimer(self)
        self.nTimer = nil
    end)
end

function UIWidgetTangMenMonitor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTangMenMonitor:UpdateInfo()
    local tTopCD = self.tTopCD
    if tTopCD then
        local tbScript = UIHelper.GetBindScript(self.WidgeSkill1)
        UIHelper.SetVisible(self.WidgeSkill1, true)
        local nIconID = Table_GetSkillIconID(tTopCD.dwSkillID, 1)
        UIHelper.SetItemIconByIconID(tbScript.ImgSkillIcon, nIconID)
        UIHelper.UpdateMask(tbScript.MaskSkill)
        local szName = Table_GetSkillName(tTopCD.dwSkillID, 1)
        UIHelper.SetLabel(tbScript.LabelSkill, UIHelper.GBKToUTF8(szName), 4)
        UIHelper.SetColor(tbScript.LabelSkill, cc.c3b(255, 255, 255))
        if tTopCD.dwLeft == 0 then
            UIHelper.SetVisible(tbScript.LabelCD, false)
            UIHelper.SetVisible(tbScript.LabelKeYong, true)
        else
            UIHelper.SetVisible(tbScript.LabelCD, true)
            UIHelper.SetVisible(tbScript.LabelKeYong, false)
            local h, m, nS = TimeLib.GetTimeToHourMinuteSecond(tTopCD.dwLeft, true)
            UIHelper.SetLabel(tbScript.LabelCD, string.format("%s", nS))
        end
    else
        UIHelper.SetVisible(self.WidgeSkill1, false)
    end

    for i, node in ipairs(self.tbWidgetSkillList) do
        local tMonitor = self.tMonitorList[i]
        local tbScript = UIHelper.GetBindScript(node)
        if tMonitor then
            UIHelper.SetVisible(node, true)
            local nIconID = Table_GetSkillIconID(tMonitor.dwSkillID, 1)
            UIHelper.SetItemIconByIconID(tbScript.ImgSkillIcon, nIconID)
            UIHelper.UpdateMask(tbScript.MaskSkill)
            local szName = Table_GetSkillName(tMonitor.dwSkillID, 1)
            UIHelper.SetLabel(tbScript.LabelSkill, UIHelper.GBKToUTF8(szName), 4)
            UIHelper.SetColor(tbScript.LabelSkill, cc.c3b(255, 255, 255))
            if tMonitor.dwLeft == 0 then
                UIHelper.SetVisible(tbScript.LabelCD, false)
                UIHelper.SetVisible(tbScript.LabelKeYong, true)
            else
                UIHelper.SetVisible(tbScript.LabelCD, true)
                UIHelper.SetVisible(tbScript.LabelKeYong, false)
                local h, m, nS = TimeLib.GetTimeToHourMinuteSecond(tMonitor.dwLeft, true)
                UIHelper.SetLabel(tbScript.LabelCD, string.format("%s", nS))
            end
        else
            UIHelper.SetVisible(node, false)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutTangMenCD)
end

function UIWidgetTangMenMonitor:UpdateData()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tTopCD
    local tMonitorList = {}
    local tForceList = Table_GetCDMonitorForce(KONGFU_ID)
    for _, v in ipairs(tForceList) do
        local dwLeft = player.GetCDLeft(v.dwCDID)
        v.dwLeft = dwLeft
        if v.bTop then
            tTopCD = v
        else
            table.insert(tMonitorList, v)
        end
    end
    self.tTopCD = tTopCD
    self.tMonitorList = tMonitorList
end

return UIWidgetTangMenMonitor