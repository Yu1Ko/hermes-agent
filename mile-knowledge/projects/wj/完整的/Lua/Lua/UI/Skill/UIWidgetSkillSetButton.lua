-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiJiBtn
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetSkillSetButton
local UIWidgetSkillSetButton = class("UIWidgetSkillSetButton")

function UIWidgetSkillSetButton:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetSkillSetButton:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetSkillSetButton:BindUIEvent()
end

function UIWidgetSkillSetButton:RegEvent()

end

function UIWidgetSkillSetButton:UpdateInfo()
    local nSetID = self.nSetID
    local szSetName  = SkillData.GetSkillSetName(self.nKungFuID, nSetID - 1) -- 转换成下表为0的nSet
    UIHelper.SetString(self.LabelGroup, szSetName)

    local nFontSize = GetStringCharCount(szSetName) >= 7 and 20 or 24
    UIHelper.SetFontSize(self.LabelGroup, nFontSize)

    UIHelper.BindUIEvent(self.BtnRename, EventType.OnClick, function()
        local nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMount().dwSkillID
        if self.nKungFuID ~= nCurrentKungFuID then
            return TipsHelper.ShowImportantBlueTip("应用本心法后可配置")
        end
        local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, szSetName, string.format("请输入配置%d的新名字", nSetID), function(szText)
            if szText == "" then
                TipsHelper.ShowNormalTip("内容不能为空")
                return
            end

            if TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then
                SkillData.SetSkillSetName(self.nKungFuID, nSetID - 1, szText)

                self:UpdateInfo()
                if self.fnRename then
                    self.fnRename()
                end
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR)
            end
        end)
        editBox:SetTitle("武学分页")
        editBox:SetMaxLength(8)
    end)
end

function UIWidgetSkillSetButton:Init(nSetID, nCurrentKungFuID, fnMainClick)
    self.nSetID = nSetID
    self.nKungFuID = nCurrentKungFuID
    UIHelper.BindUIEvent(self.BtnGroup, EventType.OnClick, fnMainClick)
    self:UpdateInfo()
end

function UIWidgetSkillSetButton:BindRenameCallback(fnRename)
    self.fnRename = fnRename
end

function UIWidgetSkillSetButton:BindClickEvent(fun)
    UIHelper.BindUIEvent(self.BtnGroup, EventType.OnClick, fun)
end

--在WidgetSkillConfiguration中BtnGroup改为Toggle的情况：
function UIWidgetSkillSetButton:InitToggle(nSetID, nCurrentKungFuID, fnSelected)
    if not g_pClientPlayer then
        return
    end

    self.nSetID = nSetID
    self.nKungFuID = nCurrentKungFuID

    local nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nCurrentKungFuID)
    UIHelper.SetSelected(self.BtnGroup, nCurrentSetID == nSetID - 1, false)

    UIHelper.BindUIEvent(self.BtnGroup, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected and fnSelected then
            fnSelected()
        end
    end)
    self:UpdateInfo()
end

return UIWidgetSkillSetButton
