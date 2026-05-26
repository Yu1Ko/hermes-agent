-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestDialogueItemView
-- Date: 2022-11-23 11:32:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestDialogueItemView = class("UIQuestDialogueItemView")

function UIQuestDialogueItemView:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIQuestDialogueItemView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestDialogueItemView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDialogue, EventType.OnClick, function()
        self.tbData.callback()
    end)
    UIHelper.BindUIEvent(self.BtnAward, EventType.OnClick, function()
        if self.tbData.funcAwardPreview then
            self.tbData.funcAwardPreview()
        end
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self._rootNode, TipsLayoutDir.TOP_CENTER, self.szContent)
    end)
end

function UIQuestDialogueItemView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuestDialogueItemView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestDialogueItemView:UpdateInfo()
    self.szContent = self.tbData.szContent
    UIHelper.SetString(self.LabelDialogue, self.szContent, 13)
   
    local bShowAward = self.tbData.szIconName and true or false
    UIHelper.SetVisible(self.MaskAward1, bShowAward)

    if self.MaskAward2 then
        UIHelper.SetVisible(self.MaskAward2, bShowAward)
    end
    if self.MaskLight then
        UIHelper.SetVisible(self.MaskLight, bShowAward)
    end

    if self.ImgIconDialogue then
        UIHelper.SetSpriteFrame(self.ImgIconDialogue, self.tbData.szDialogueIcon)
    end

    if self.tbData.szDialogueIconBg then
        UIHelper.SetSpriteFrame(self.ImgDialogueBg, self.tbData.szDialogueIconBg)
    end
    UIHelper.SetSwallowTouches(self.BtnDialogue, false)
    UIHelper.SetVisible(self.Eff_UIbaoXiang, bShowAward)
    UIHelper.SetVisible(self.ImgAward, bShowAward)

    local nQuestID = self.tbData.nQuestID
    local tbAwardList = nil
    if nQuestID then 
        tbAwardList = QuestData.GetCurQuestAwardList(nQuestID) 
    end
    UIHelper.SetVisible(self.BtnAward, tbAwardList and #tbAwardList ~= 0)

    local nTextNum = UIHelper.GetUtf8Len(self.szContent)
    UIHelper.SetVisible(self.BtnDetail, nTextNum >= 14)
    UIHelper.SetSwallowTouches(self.BtnDetail, true)
end


return UIQuestDialogueItemView