-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelQingMingView
-- Date: 2026-03-10 14:39:25
-- Desc: ?
-- ---------------------------------------------------------------------------------
-- UIMgr.Open(VIEW_ID.PanelQingMing)
local DEFAULT_NPC_ID = 1
local TASK_COUNT = 4
local UIPanelQingMingView = class("UIPanelQingMingView")

function UIPanelQingMingView:OnEnter(dwNpcID)
    if not dwNpcID then
        dwNpcID = DEFAULT_NPC_ID
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(dwNpcID)
end

function UIPanelQingMingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    QingmingSoulData.UnInit()
end

function UIPanelQingMingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelQingMingView:RegEvent()
    Event.Reg(self, "QUEST_FINISHED", function ()
        QingmingSoulData.UpdateTaskStatus()
        self:UpdateTaskList()
    end)
end

function UIPanelQingMingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelQingMingView:Init(dwNpcID)
    QingmingSoulData.Init()
    QingmingSoulData.LoadNpcData(dwNpcID)
    QingmingSoulData.UpdateTaskStatus()

    self:UpdateNpcInfo()
    Timer.Add(self, 2.8, function ()
        self:UpdateTaskList()
    end)
end

function UIPanelQingMingView:UpdateNpcInfo()
    local tbNpcInfo = QingmingSoulData.GetNpcInfo()
    if not tbNpcInfo then
        return
    end

    UIHelper.SetString(self.LabelNpcName, UIHelper.GBKToUTF8(tbNpcInfo.tNpcData.szName))
    UIHelper.SetString(self.LabelNpcTitle, UIHelper.GBKToUTF8(tbNpcInfo.tNpcData.szTitle))
    local szHometown = UIHelper.GBKToUTF8(tbNpcInfo.tNpcData.szHometown)
    szHometown = string.gsub(szHometown, "%s+", "\n\n")
    UIHelper.SetString(self.LabelNpcHometown, szHometown)
    if tbNpcInfo.tNpcData.szNpcSFXPath then
        UIHelper.SetSFXPath(self.Eff_Npc, tbNpcInfo.tNpcData.szNpcSFXPath)
        UIHelper.SetVisible(self.Eff_Npc, true)
    end
end

function UIPanelQingMingView:UpdateTaskList()
    local tbNpcInfo = QingmingSoulData.GetNpcInfo()
    if not tbNpcInfo or not tbNpcInfo.tNpcData then
        return
    end
    
    local tNpcData = tbNpcInfo.tNpcData

    UIHelper.SetVisible(self.WidgetComplete, false)
    if tbNpcInfo.bChapterComplete then
        if Storage.QingMingEffect.bChapterEffectShown then
            Timer.Add(self, 0.75, function ()
                UIHelper.SetVisible(self.WidgetComplete, true)
                UIHelper.SetVisible(self.Eff_Complete, false)
                UIHelper.SetVisible(self.ImgComplete, true)
            end)
        else
            Storage.QingMingEffect.bChapterEffectShown = true
            Storage.QingMingEffect.Flush()

            for i = 1, TASK_COUNT do
                UIHelper.SetVisible(self.tbEffNormalList[i], false)
                UIHelper.SetVisible(self.tbEffOverList[i], false)
                UIHelper.SetString(self.tbLabelContentList[i], "")

                local szContent = UIHelper.GBKToUTF8(tNpcData["szTaskContent" .. i] or "")
                szContent = string.gsub(szContent, "%s+", "\n\n")
                Timer.Add(self, 0.5 * i, function ()
                    UIHelper.SetVisible(self.toWidgetList[i], true)
                    UIHelper.SetVisible(self.tbEffOverList[i], true)
                    Timer.AddFrame(self, 1, function ()
                        UIHelper.SetString(self.tbLabelContentList[i], szContent)
                    end)
                    if i == TASK_COUNT then
                        UIHelper.SetVisible(self.WidgetComplete, true)
                        UIHelper.SetVisible(self.Eff_Complete, true)
                        UIHelper.SetVisible(self.ImgComplete, false)
                    end
                end)

                Storage.QingMingEffect.tShownEffect[i] = true
            end
            Storage.QingMingEffect.tShownEffect.Flush()
        end
    end

    for i = 1, TASK_COUNT do
        local bFinished = tbNpcInfo.tTaskStatus[i]
        local bShown = Storage.QingMingEffect.tShownEffect[i]
        local szContent = UIHelper.GBKToUTF8(tNpcData["szTaskContent" .. i] or "")
        szContent = string.gsub(szContent, "%s+", "\n\n")
        if bFinished then
            if not bShown then
                -- 完成了且没播放过
                UIHelper.SetVisible(self.tbEffNormalList[i], false)
                UIHelper.SetVisible(self.tbEffOverList[i], true)
                UIHelper.SetString(self.tbLabelContentList[i], "")
                Storage.QingMingEffect.tShownEffect[i] = true
                Storage.QingMingEffect.Flush()
                Timer.Add(self, 0.5 * i, function ()
                    UIHelper.SetVisible(self.toWidgetList[i], true)
                    Timer.AddFrame(self, 1, function ()
                        UIHelper.SetString(self.tbLabelContentList[i], szContent)
                    end)
                end)
            else
                UIHelper.SetVisible(self.tbEffNormalList[i], true)
                UIHelper.SetVisible(self.tbEffOverList[i], false)
                UIHelper.SetString(self.tbLabelContentList[i], "")
                UIHelper.SetVisible(self.toWidgetList[i], true)
                Timer.AddFrame(self, 1, function ()
                    UIHelper.SetString(self.tbLabelContentList[i], szContent)
                end)
            end
        else
            UIHelper.SetVisible(self.tbEffNormalList[i], false)
            UIHelper.SetVisible(self.tbEffOverList[i], false)
            UIHelper.SetString(self.tbLabelContentList[i], "")
        end
    end
end

return UIPanelQingMingView