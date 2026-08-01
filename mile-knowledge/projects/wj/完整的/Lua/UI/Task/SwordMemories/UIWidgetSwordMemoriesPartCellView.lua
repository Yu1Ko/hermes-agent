-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSwordMemoriesPartCell
-- Date: 2023-09-11 17:48:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSwordMemoriesPartCell = class("UIWidgetSwordMemoriesPartCell")

function UIWidgetSwordMemoriesPartCell:OnEnter(tbSectionInfo, scriptParent, bSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSectionInfo = tbSectionInfo
    self.scriptParent = scriptParent
    self.bDefaultSelected = bSelected
    self:UpdateInfo()
end

function UIWidgetSwordMemoriesPartCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSwordMemoriesPartCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPlayShuoShu, EventType.OnClick, function()
        local nSoundID = self.tbSectionInfo.nSoundID
        if nSoundID and nSoundID ~= 0 then
            SwordMemoriesData.StartPlaySoundBySoundID(nSoundID)
        end
    end)

    UIHelper.BindUIEvent(self.TogTitle, EventType.OnSelectChanged, function(_, bSelected)
        UIHelper.SetVisible(self.WidgetContent, not bSelected)
        UIHelper.LayoutDoLayout(self.WidgetContent)
        UIHelper.LayoutDoLayout(self._rootNode)
        self.scriptParent:ScrollViewDoLayout(self)
        self.scriptParent:UpdateSelectedNum(bSelected)
    end)
end

function UIWidgetSwordMemoriesPartCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSwordMemoriesPartCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSwordMemoriesPartCell:UpdateInfo()
    local tbSectionInfo = self.tbSectionInfo
    local nSoundID = tbSectionInfo.nSoundID
    local bFinished, bLock = SwordMemoriesData.IsSectionFinished(tbSectionInfo)
    -- UIHelper.SetVisible(self.LabelPartLocked, bLock)

    local szLock = UIHelper.GBKToUTF8(tbSectionInfo.szName) .. "·未解锁"
    local szUnLock = UIHelper.GBKToUTF8(tbSectionInfo.szName)
    UIHelper.SetString(self.LabelPartTitle, (bLock and not SwordMemoriesData.IsShowAllSection()) and szLock or szUnLock)
    UIHelper.SetString(self.LabelPartTitleUp, (bLock and not SwordMemoriesData.IsShowAllSection()) and szLock or szUnLock)

    local szContent = (bFinished or SwordMemoriesData.IsShowAllSection()) and self:GetPureString(tbSectionInfo.szDesc) or ""
    UIHelper.SetString(self.LabelChapterTitle, szContent)

    UIHelper.SetVisible(self.WidgetTagCurrent, not bFinished and not bLock)

    local szLockText = SwordMemoriesData.GetLockSectionContent(tbSectionInfo)

    UIHelper.SetString(self.LabelLocked, szLockText)

    UIHelper.SetVisible(self.LabelLocked, bLock or (not bFinished and not bLock))
    UIHelper.SetVisible(self.LayoutBtns, (bFinished or SwordMemoriesData.IsShowAllSection()) and nSoundID ~= 0)
    UIHelper.SetVisible(self.BtnPlayShuoShu, (bFinished or SwordMemoriesData.IsShowAllSection()) and nSoundID ~= 0)
    UIHelper.SetSwallowTouches(self.BtnPlayShuoShu, true)
    UIHelper.LayoutDoLayout(self.LayoutBtns)

    UIHelper.SetSelected(self.TogTitle, self.bDefaultSelected, false)
    UIHelper.SetVisible(self.WidgetContent, not self.bDefaultSelected)
    UIHelper.SetVisible(self._rootNode, true)

    UIHelper.WidgetFoceDoAlign(self)--强制刷挂靠更新WidgetContent的宽度以及LabelChapterTitle的每行的最大宽度
    self.LabelChapterTitle:updateContent()--强制更新LabelChapterTitle高度

    self:UpdateLayoutState()
    UIHelper.LayoutDoLayout(self.WidgetContent)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIWidgetSwordMemoriesPartCell:UpdateLayoutState()
    local bVis = false
    for  nIndex, btn in ipairs(self.tbBtns) do
        if UIHelper.GetVisible(btn) then
            bVis =true
            break
        end
    end
    UIHelper.SetVisible(self.LayoutBtns, bVis)
end

function UIWidgetSwordMemoriesPartCell:GetPureString(szInfo)
    local szText = ""
    local _, aInfo = GWTextEncoder_Encode(szInfo)
    if aInfo then
        for k, v in pairs(aInfo) do
            if v.name == "text" then
                szText = szText .. UIHelper.GBKToUTF8(v.context)
            elseif v.name == "G" then
                szText = szText .. g_tStrings.STR_TWO_CHINESE_SPACE
            elseif v.name == "N" then 
                local szName = UIHelper.GBKToUTF8(GetEncodeName(v))
                szText = szText .. szName
            end
        end
    end
    return szText
end

function UIWidgetSwordMemoriesPartCell:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self.TogTitle, bSelected, bCallback)
    UIHelper.SetVisible(self.WidgetContent, not bSelected)
    UIHelper.LayoutDoLayout(self.WidgetContent)
    UIHelper.LayoutDoLayout(self._rootNode)
end

return UIWidgetSwordMemoriesPartCell