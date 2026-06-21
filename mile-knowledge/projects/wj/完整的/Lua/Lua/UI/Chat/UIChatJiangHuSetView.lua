-- ---------------------------------------------------------------------------------
-- PanelChatTextExpression
-- ---------------------------------------------------------------------------------

local UIChatJiangHuSetView = class("UIChatJiangHuSetView")

local MAX_JIANGHU_COUNTS = 300

function UIChatJiangHuSetView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.tJiangHuCell = {}
        self.nJiangHuCount = 0
    end

    self:UpdateInfo()
end

function UIChatJiangHuSetView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.tJiangHuCell = {}
end

function UIChatJiangHuSetView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRecover, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelNormalConfirmation, "您确定将表情语言还原成默认？", function()
            self:RecoverDefaults()
        end, function()
            UIMgr.Close(VIEW_ID.PanelNormalConfirmation)
        end)
    end)
end

function UIChatJiangHuSetView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatJiangHuSetView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatJiangHuSetView:UpdateInfo()
    self:UpdateList()
    self:UpdateEditText()
end

function UIChatJiangHuSetView:UpdateList()
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroup)
    UIHelper.RemoveAllChildren(self.ScrollViewLeftList)

    local tJiangHuLanguage = JiangHuLanguageData.GetJiangHuData()
    local loadIndex = 0
    self.nJiangHuCount = #tJiangHuLanguage
    local loadCount = #tJiangHuLanguage

    self.newTog = UIHelper.AddPrefab(PREFAB_ID.WidgetChatTextExpressionListCell, self.ScrollViewLeftList) assert(self.newTog)
    UIHelper.ToggleGroupAddToggle(self.TogGroup, self.newTog.TogTextExpressionNew)
    UIHelper.SetVisible(self.newTog.TogTextExpressionNew, true)
    UIHelper.SetVisible(self.newTog.TogTextExpression, false)
    UIHelper.SetVisible(self.newTog.ImgIcon, false)
    UIHelper.BindUIEvent(self.newTog.TogTextExpressionNew, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            self:UpdateEditText()
        end
    end)

    if loadCount > 0 then
        self.nJiangHuLanguageID = Timer.AddFrameCycle(self , 1 , function ()
            for i = 1,2, 1 do
                loadIndex = loadIndex + 1
                local jiangHuData = tJiangHuLanguage[loadIndex]
                local editTog = UIHelper.AddPrefab(PREFAB_ID.WidgetChatTextExpressionListCell, self.ScrollViewLeftList) assert(editTog)
                UIHelper.ToggleGroupAddToggle(self.TogGroup, editTog.TogTextExpression)
                self.tJiangHuCell[loadIndex] = editTog
                UIHelper.SetString(editTog.LabelContent, jiangHuData[1])
                UIHelper.SetString(editTog.LabelSelect, jiangHuData[1])
                UIHelper.BindUIEvent(editTog.TogTextExpression, EventType.OnSelectChanged, function(btn, bSelected)
                    if bSelected then
                        self:UpdateEditText(jiangHuData)
                    end
                end)

                if loadIndex == loadCount then
                    Timer.DelTimer(self , self.nJiangHuLanguageID)
                    break
                end
            end
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftList)
        end)
    end
end

function UIChatJiangHuSetView:UpdateEditText(tJiangHu)
    if tJiangHu then
        UIHelper.SetText(self.EditBoxTitle, string.gsub(tJiangHu[1], "/", ""))
        UIHelper.SetText(self.EditBoxAlone, tJiangHu[2])
        UIHelper.SetText(self.EditBoxGoals, tJiangHu[3])

        UIHelper.SetVisible(self.BtnNew, false)

        UIHelper.SetVisible(self.BtnCompile, true)
        UIHelper.BindUIEvent(self.BtnCompile, EventType.OnClick, function()
            self:ModifyJiangHu(tJiangHu)
        end)

        UIHelper.SetVisible(self.BtnDelete, true)
        UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()

            local szJiangHuSingleDelete = "您确定将'" .. tJiangHu[1] .. "'用语删除吗？"
            UIMgr.Open(VIEW_ID.PanelNormalConfirmation, szJiangHuSingleDelete, function()
                self:DeleteJiangHu(tJiangHu)
            end, function()
                UIMgr.Close(VIEW_ID.PanelNormalConfirmation)
            end)
        end)
    else
        UIHelper.SetText(self.EditBoxTitle, "")
        UIHelper.SetText(self.EditBoxAlone, "")
        UIHelper.SetText(self.EditBoxGoals, "")
        UIHelper.SetVisible(self.BtnCompile, false)
        UIHelper.SetVisible(self.BtnDelete, false)
        UIHelper.SetVisible(self.BtnNew, true)
        UIHelper.BindUIEvent(self.BtnNew, EventType.OnClick, function()
            self:AddNewJiangHu()
        end)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIChatJiangHuSetView:IsBlankString(szContent)
    if not szContent or szContent == "" then
        return true
    end
    local szNoBlank = string.gsub(szContent, " +", "")
    if not szNoBlank or szNoBlank == "" then
        return true
    end
    return false
end

function UIChatJiangHuSetView:AddNewJiangHu()
    if self.nJiangHuCount + 1 > MAX_JIANGHU_COUNTS then
        return OutputMessage("MSG_SYS", g_tStrings.STR_JIANGHU_MAX_COMMAND_NOTICE)
    end

    local szCmd = UIHelper.GetText(self.EditBoxTitle)
    local szAlone = UIHelper.GetText(self.EditBoxAlone)
    local szGoals = UIHelper.GetText(self.EditBoxGoals)

    szAlone = string.gsub(szAlone, "\r\n", "")
    szAlone = string.gsub(szAlone, "\n", "")
    szGoals = string.gsub(szGoals, "\r\n", "")
    szGoals = string.gsub(szGoals, "\n", "")

    if
        self:IsBlankString(szCmd) or
        self:IsBlankString(szAlone) or
        self:IsBlankString(szGoals)
    then
        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_JIANGHU_NONE_NOTICE)
    end

    if string.find(szCmd, "/") ~= 1 then
        szCmd = "/" .. szCmd
    end

    if string.find(szAlone, "$N") ~= 1 then
        szAlone = "$N" .. szAlone
    end

    if string.find(szGoals, "$N") ~= 1 then
        szGoals = "$N" .. szGoals
    end

    if JiangHuLanguageData.IsJiangHuData(szCmd) then
        return OutputMessage("MSG_SYS", g_tStrings.STR_JIANGHU_EXIST_NOTICE)
    end

    local tJiangHu = {szCmd, szAlone, szGoals}
    JiangHuLanguageData.AddNew(tJiangHu)
    self.nJiangHuCount = self.nJiangHuCount + 1

    local editTog = UIHelper.AddPrefab(PREFAB_ID.WidgetChatTextExpressionListCell, self.ScrollViewLeftList) assert(editTog)
    UIHelper.ToggleGroupAddToggle(self.TogGroup, editTog.TogTextExpression)
    self.tJiangHuCell[self.nJiangHuCount] = editTog
    UIHelper.SetString(editTog.LabelContent, szCmd)
    UIHelper.SetString(editTog.LabelSelect, szCmd)
    UIHelper.BindUIEvent(editTog.TogTextExpression, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            self:UpdateEditText(tJiangHu)
        end
    end)

    UIHelper.SetToggleGroupSelected(self.TogGroup, self.nJiangHuCount)
    self:UpdateEditText(tJiangHu)
    Event.Dispatch("JiangHuWordUpdate")
end

function UIChatJiangHuSetView:ModifyJiangHu(tOldJiangHu)
    local szCmd = UIHelper.GetText(self.EditBoxTitle)
    local szAlone = UIHelper.GetText(self.EditBoxAlone)
    local szGoals = UIHelper.GetText(self.EditBoxGoals)

    szAlone = string.gsub(szAlone, "\r\n", "")
    szAlone = string.gsub(szAlone, "\n", "")
    szGoals = string.gsub(szGoals, "\r\n", "")
    szGoals = string.gsub(szGoals, "\n", "")

    if
        self:IsBlankString(szCmd) or
        self:IsBlankString(szAlone) or
        self:IsBlankString(szGoals)
    then
        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_JIANGHU_NONE_NOTICE)
    end

    if string.find(szCmd, "/") ~= 1 then
        szCmd = "/" .. szCmd
    end

    if string.find(szAlone, "$N") ~= 1 then
        szAlone = "$N" .. szAlone
    end

    if string.find(szGoals, "$N") ~= 1 then
        szGoals = "$N" .. szGoals
    end

    if JiangHuLanguageData.IsJiangHuData(szCmd, tOldJiangHu) then
        return OutputMessage("MSG_SYS", g_tStrings.STR_JIANGHU_EXIST_NOTICE)
    end

    if szCmd == tOldJiangHu[1] and szAlone == tOldJiangHu[2] and szGoals == tOldJiangHu[3] then
        return
    end

    local tJiangHu = {szCmd, szAlone, szGoals}
    local nPos = JiangHuLanguageData.GetNPosOfJiangHuLanguage(tOldJiangHu)
    if not nPos then
        LOG.ERROR("CANT FIND JIANGHUDATA")
        return
    end
    JiangHuLanguageData.Modify(tJiangHu, nPos)
    local editTog = self.tJiangHuCell[nPos]
    UIHelper.SetString(editTog.LabelContent, szCmd)
    UIHelper.SetString(editTog.LabelSelect, szCmd)
    UIHelper.BindUIEvent(editTog.TogTextExpression, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            self:UpdateEditText(tJiangHu)
        end
    end)

    UIHelper.SetToggleGroupSelected(self.TogGroup, nPos)
    self:UpdateEditText(tJiangHu)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "修改成功!")
    Event.Dispatch("JiangHuWordUpdate")
end

function UIChatJiangHuSetView:DeleteJiangHu(tJiangHu)
    local nPos = JiangHuLanguageData.GetNPosOfJiangHuLanguage(tJiangHu)
    if not nPos then
        LOG.ERROR("CANT FIND JIANGHUDATA")
        return
    end
    JiangHuLanguageData.Delete(nPos)
    local editTog = self.tJiangHuCell[nPos]
    for i = nPos + 1, self.nJiangHuCount, 1 do
        self.tJiangHuCell[i - 1] = self.tJiangHuCell[i]
    end
    self.tJiangHuCell[self.nJiangHuCount] = nil
    UIHelper.ToggleGroupRemoveToggle(self.TogGroup, editTog.TogTextExpression)
    UIHelper.RemoveFromParent(editTog._rootNode, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftList)

    if nPos < self.nJiangHuCount then
        local tJiangHu = JiangHuLanguageData.GetJiangHuDataAtNPos(nPos)
        editTog = self.tJiangHuCell[nPos]
        UIHelper.SetToggleGroupSelected(self.TogGroup, nPos)
        self:UpdateEditText(tJiangHu)
    else
        UIHelper.SetToggleGroupSelected(self.TogGroup, 0)
        self:UpdateEditText()
    end

    self.nJiangHuCount = self.nJiangHuCount - 1
    Event.Dispatch("JiangHuWordUpdate")
    TipsHelper.ShowNormalTip("删除成功。")
end

function UIChatJiangHuSetView:RecoverDefaults()
    JiangHuLanguageData.BackDefaults()
    self:UpdateEditText()
    self:UpdateList()
    Event.Dispatch("JiangHuWordUpdate")
end

return UIChatJiangHuSetView