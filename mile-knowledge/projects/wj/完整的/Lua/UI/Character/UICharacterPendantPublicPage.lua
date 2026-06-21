-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantPublicPage
-- Date: 2024-09-10 19:18:39
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UICharacterPendantPublicPage
UICharacterPendantPublicPage = class("UICharacterPendantPublicPage")

local IgnoreMainPage = {
    [AccessoryMainPageIndex.Exterior] = true,
    [AccessoryMainPageIndex.SkillSkin_WXLSpecal] = true,
}

local function EmptyFunc() end
local tbSearchPlaceHolder = {
    [AccessoryMainPageIndex.Pendant] = "挂件名字",
    [AccessoryMainPageIndex.Effect] = "特效名字",
    [AccessoryMainPageIndex.Avatar] = "头像名字",
    [AccessoryMainPageIndex.IdleAction] = "站姿",
    [AccessoryMainPageIndex.SkillSkin] = "武技殊影",
    [AccessoryMainPageIndex.SkillSkin_DX] = "武技殊影",
}
local tbFilter = {
    [AccessoryMainPageIndex.Pendant] = FilterDef.Accessory_Pendant,
    [AccessoryMainPageIndex.Effect] = FilterDef.Accessory_Effect,
    [AccessoryMainPageIndex.Avatar] = FilterDef.Accessory_Avatar,
    [AccessoryMainPageIndex.IdleAction] = FilterDef.Accessory_IdleAction,
    [AccessoryMainPageIndex.SkillSkin] = FilterDef.Accessory_SkillSkin,
    [AccessoryMainPageIndex.SkillSkin_DX] = FilterDef.Accessory_SkillSkin,
}
---------------------------------重载函数-------------------------------
UICharacterPendantPublicPage.Init                           = EmptyFunc
UICharacterPendantPublicPage.RegEvent                       = EmptyFunc
UICharacterPendantPublicPage.BindUIEvent                    = EmptyFunc
UICharacterPendantPublicPage.OnClickBtnHangingPetPosition   = EmptyFunc
UICharacterPendantPublicPage.OnClickBtnFastTakeOff          = EmptyFunc
UICharacterPendantPublicPage.OnClickBtnDefault              = EmptyFunc
UICharacterPendantPublicPage.OnClickTogAccessory            = EmptyFunc
UICharacterPendantPublicPage.BindUIEvent                    = EmptyFunc
UICharacterPendantPublicPage.UpdateInfo                     = EmptyFunc
UICharacterPendantPublicPage.ClearSelect                    = EmptyFunc
-----------------------------------------------------------------------

function UICharacterPendantPublicPage:OnEnter()
    self.nSelectMainPage = 1
    self.bIsNowCollectPage = false
    self.DataModel= {}

    self:Init()
    self:RegPublicEvent()
end

function UICharacterPendantPublicPage:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self.DataModel.UnInit()
end

-- 在事件OnCharacterPendantSelected后，保证通用UIItem的响应脚本唯一
function UICharacterPendantPublicPage:BindPublicUIItem()
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetEditboxTextHorizontalAlign(scriptPublic.EditPaginate, TextHAlignment.CENTER)
    UIHelper.BindUIEvent(scriptPublic.BtnFastTakeOff, EventType.OnClick, function(btn)
        self:OnClickBtnFastTakeOff(btn)
    end)

    UIHelper.BindUIEvent(scriptPublic.BtnHangingPetPosition, EventType.OnClick, function(btn)
        self:OnClickBtnHangingPetPosition(btn)
    end)

    UIHelper.BindUIEvent(scriptPublic.BtnDefault, EventType.OnClick, function(btn)
        self:OnClickBtnDefault(btn)
    end)

    UIHelper.BindUIEvent(scriptPublic.TogAccessory, EventType.OnTouchBegan, function()
        self:OnClickTogAccessory()
    end)

    UIHelper.BindUIEvent(scriptPublic.BtnRight, EventType.OnClick, function()
        local dwMaxPageCount, dwCurrentPage = self.DataModel.GetCurPageInfo()
        if dwCurrentPage >= dwMaxPageCount then
            return
        end

        self:ClearPublicSelect()

        self.DataModel.SetCurrentPage(dwCurrentPage + 1)
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(scriptPublic.BtnLeft, EventType.OnClick, function()
        local dwMaxPageCount, dwCurrentPage = self.DataModel.GetCurPageInfo()
        if dwCurrentPage <= 1 then
            return
        end

        self:ClearPublicSelect()

        self.DataModel.SetCurrentPage(dwCurrentPage - 1)
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(scriptPublic.TogSift, EventType.OnClick, function()
        self:ClearPublicSelect()
        if self.tbFilter then
            self.scriptFilterTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, scriptPublic.TogSift, TipsLayoutDir.Right, self.tbFilter)
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(scriptPublic.EditPaginate, function()
            self:UpdateEditPaginate()
            self:UpdateButtonInfo()
        end)

        UIHelper.RegisterEditBoxEnded(scriptPublic.EditKindSearch, function()
            local szSearch = UIHelper.GetString(scriptPublic.EditKindSearch)
            self.DataModel.SetCurrentPage(1)
            self.DataModel.SetSearchText(szSearch)
            self.DataModel.UpdateFilterList()
            self:UpdateInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(scriptPublic.EditPaginate, function()
            self:UpdateEditPaginate()
            self:UpdateButtonInfo()
        end)

        UIHelper.RegisterEditBoxReturn(scriptPublic.EditKindSearch, function()
            local szSearch = UIHelper.GetString(scriptPublic.EditKindSearch)
            self.DataModel.SetCurrentPage(1)
            self.DataModel.SetSearchText(szSearch)
            self.DataModel.UpdateFilterList()
            self:UpdateInfo()
        end)
    end

    UIHelper.BindUIEvent(scriptPublic.BtnDIYDecoration, EventType.OnClick, function()
        if self.nSelectMainPage == AccessoryMainPageIndex.Effect then
            Event.Dispatch(EventType.OpenCloseCharacterCustomEffect, true)
        elseif self.nSelectMainPage == AccessoryMainPageIndex.Pendant then
            Event.Dispatch(EventType.OpenCloseCharacterCustomPendant, true, self.DataModel.nRepresentType, self.DataModel.nPendantType)
        end

    end)
end

function UICharacterPendantPublicPage:RegPublicEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:ClearSelect()
        self:ClearPublicSelect()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:ClearSelect()
        self:ClearPublicSelect()
    end)

    Event.Reg(self, EventType.OnSceneTouchBegan, function()
        self:ClearSelect()
        self:ClearPublicSelect()
    end)

    Event.Reg(self, EventType.OnCharacterPendantSelected, function (nPage)
        if self.nSelectMainPage == AccessoryMainPageIndex.Effect then
            Event.Dispatch(EventType.OpenCloseCharacterCustomEffect, false)
        end

        if self.nSelectMainPage == AccessoryMainPageIndex.Pendant then
             Event.Dispatch(EventType.OpenCloseCharacterCustomPendant, false)
        end

        self.nSelectMainPage = nPage

        local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
        UIHelper.SetVisible(scriptPublic._rootNode, not IgnoreMainPage[self.nSelectMainPage])
        UIHelper.SetVisible(scriptPublic.WidgetSearch, not IgnoreMainPage[self.nSelectMainPage])
        -- UIHelper.SetVisible(scriptPublic.WidgetTogFoldEffect, self.nSelectMainPage == AccessoryMainPageIndex.IdleAction)
        if self.nSelectMainPage ~= self.nMainPage then
            return
        end
        self.tbFilter = self.DataModel.GetFilterMenu and self.DataModel.GetFilterMenu() or tbFilter[self.nMainPage]
        self:BindPublicUIItem()

        UIHelper.SetText(scriptPublic.EditKindSearch, self.DataModel.GetSearchText())
        self:ShowWidgetEmpty(false) -- 怕有地方忘了设空状态，所以这里补一下
        self:ShowImgTitle(true) -- 怕有地方忘了重置，所以这里补一下
        self:ShowWidgetSearch(true)
        self:ShowWidgetCurrency(false)
        self:ShowLabelGetTips(false)
        self:UpdateSearchPlaceHolder()
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnCharacterPendantSelectedSubPage, function (nSubPage)
        -- if self.nSelectMainPage == AccessoryMainPageIndex.Pendant and (nSubPage == 1 or nSubPage == 0) then
        --     OutputMessage("MSG_ANNOUNCE_YELLOW", "稍后开启，敬请期待。")
        --     return
        -- end
        if self.nSelectMainPage ~= self.nMainPage then
            return
        end

        if self.nMainPage == AccessoryMainPageIndex.Effect then
            Event.Dispatch(EventType.OpenCloseCharacterCustomEffect, false)
        end

        if self.nMainPage == AccessoryMainPageIndex.Pendant then
            Event.Dispatch(EventType.OpenCloseCharacterCustomPendant, false)
        end

        local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
        if scriptPublic then
            UIHelper.SetText(scriptPublic.EditKindSearch, "")
        end
        self.DataModel.SetCurrentPage(1)
        self.DataModel.SetSelectType(nSubPage)
        self.DataModel.EmptyAllFilter()
        if self.tbFilter then
            self.tbFilter.Reset()
        end

        self.DataModel.UpdateFilterList()
        self:UpdateButtonInfo()
        self:UpdateInfo()
        -- Event.Dispatch(EventType.ON_UPDATE_CURRENT_PENDANT, self.nSelectMainPage)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function(editbox, nCurNum)
        if not self:IsNowActivity() then
            return
        end

        local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
        if not scriptPublic then
            return
        end

        if editbox ~= scriptPublic.EditPaginate then return end
        self:UpdateEditPaginate(nCurNum)
        self:UpdateButtonInfo()
    end)
end

function UICharacterPendantPublicPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UICharacterPendantPublicPage:SetNowCollectPage(bIsNowCollectPage)
    self.bIsNowCollectPage = bIsNowCollectPage
end

function UICharacterPendantPublicPage:BindMainPageIndex(nIndex)
    self.nMainPage = nIndex
end

function UICharacterPendantPublicPage:BindDataModel(DataModel)
    local function createProxy(table, target)
        setmetatable(table, {
            __index = function(_, k) return target[k] end,
            __newindex = function(_, k, v) target[k] = v end,
            __call = function(_, ...) return target(...) end,
            __pairs = function() return pairs(target) end,
            __ipairs = function() return ipairs(target) end,
            __metatable = "DataModelProxy"
        })
    end

    createProxy(self.DataModel, DataModel)
end

function UICharacterPendantPublicPage:UpdateButtonInfo()
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end

    self:ShowBtnFastTakeOff(false)
    self:ShowBtnHangingPetPosition(false)
    self:ShowTogAccessory(false)
    self:ShowBtnDefault(false)
    self:ShowBtnCustom(false)

    if self.DataModel.GetCollectionProgressTips then
        local szText
        local nTotalNum, nHaveNum
        if self.bIsNowCollectPage and self.DataModel.GetCollectedNum then
            szText = "已收藏：%d/%d"
            nTotalNum, nHaveNum = self.DataModel.GetCollectedNum()
        else
            szText = "已拥有：%d/%d"
            nTotalNum, nHaveNum = self.DataModel.GetCollectionProgressTips()
        end

        UIHelper.SetString(scriptPublic.LabelAccessoryNumber, string.format(szText, nHaveNum, nTotalNum))
    end

    if self.DataModel.GetCurPageInfo then
        local nTotalPage, nCurPage = self.DataModel.GetCurPageInfo()
        nTotalPage = nTotalPage > 0 and nTotalPage or 1
        UIHelper.SetString(scriptPublic.LabelPaginate, string.format("/%d", nTotalPage))
        UIHelper.SetString(scriptPublic.EditPaginate, nCurPage)
    end
end

function UICharacterPendantPublicPage:UpdateSearchPlaceHolder()
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end

    local szSearchPlaceHolder = tbSearchPlaceHolder[self.nMainPage] or "名称"
    UIHelper.SetPlaceHolder(scriptPublic.EditKindSearch, szSearchPlaceHolder)
end

function UICharacterPendantPublicPage:UpdateEditPaginate(nPage)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end

    if not nPage then
        local szPage = UIHelper.GetString(scriptPublic.EditPaginate)
        nPage = tonumber(szPage)
    end

    local nTotalPage, nCurPage = self.DataModel.GetCurPageInfo()
    if not nPage or nPage <= 0 then
        nPage = nCurPage
    elseif nPage > nTotalPage then
        nPage = nTotalPage
    end

    UIHelper.SetString(scriptPublic.EditPaginate, tostring(nPage))

    if nPage == nCurPage then
        return
    end

    self.DataModel.SetCurrentPage(nPage)
    self:UpdateInfo()
    -- Event.Dispatch(EventType.ON_UPDATE_CURRENT_PENDANT, self.nSelectMainPage)
end

function UICharacterPendantPublicPage:ClearPublicSelect()
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if scriptPublic then
        if scriptPublic.TogAccessory then
            UIHelper.SetSelected(scriptPublic.TogAccessory, false)
        end
    end

    if self.scriptItemTip then
        UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
    end

    UIHelper.SetSelected(self.TogSift, false)
end
-----------------------------通用函数---------------------------------
function UICharacterPendantPublicPage:IsNowActivity()
    -- 当前选中页
    return self.nSelectMainPage == self.nMainPage
end

function UICharacterPendantPublicPage:GetItemTips()
    local parent = self.WidgetItemCard
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if scriptPublic then
        parent = scriptPublic.WidgetItemCard
    end

    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, parent)
    end

    return self.scriptItemTip
end

function UICharacterPendantPublicPage:ShowWidgetEmpty(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.WidgetEmpty_Public, bShow)
end

function UICharacterPendantPublicPage:ShowTogAccessory(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.TogAccessory, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.WidgetAccessory)
end

function UICharacterPendantPublicPage:ShowBtnHangingPetPosition(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.BtnHangingPetPosition, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.WidgetAccessory)
end

function UICharacterPendantPublicPage:ShowBtnFastTakeOff(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.BtnFastTakeOff, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.WidgetAccessory)
end

function UICharacterPendantPublicPage:ShowBtnDefault(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.BtnDefault, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.WidgetAccessory)
end

function UICharacterPendantPublicPage:ShowBtnCustom(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.BtnDIYDecoration, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.WidgetAccessory)
end

function UICharacterPendantPublicPage:ShowPublic(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic._rootNode, bShow)
end

function UICharacterPendantPublicPage:ShowImgTitle(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.ImgTitle, bShow)
end

function UICharacterPendantPublicPage:ShowWidgetSearch(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.WidgetSearch, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.LayoutRightTop)
end

function UICharacterPendantPublicPage:ShowLabelGetTips(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.LabelGetTips, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.LayoutRightTop)
end

function UICharacterPendantPublicPage:ShowWidgetCurrency(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.WidgetCurrency, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.LayoutRightTop)
end

function UICharacterPendantPublicPage:ShowLayoutGetNum(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.LayoutGetNum, bShow)
end

function UICharacterPendantPublicPage:SetGetTipsLabel(szTips)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetString(scriptPublic.LabelGetTips, szTips)
end

function UICharacterPendantPublicPage:SetLabelEmpty(szEmptyTips)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetString(scriptPublic.LabelEmpty, szEmptyTips)
end

function UICharacterPendantPublicPage:SetLabelAccessory01(szDesc)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetString(scriptPublic.LabelAccessory01, szDesc)
end

function UICharacterPendantPublicPage:SetLabelAccessory02(szDesc)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetString(scriptPublic.LabelAccessory02, szDesc)
end

function UICharacterPendantPublicPage:SetLabelAccessoryTipsNum(szNum)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetString(scriptPublic.LabelAccessoryTipsNum, szNum)
end

function UICharacterPendantPublicPage:SetLabelAccessoryTogNum(szNum)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetString(scriptPublic.LabelAccessoryTogNum, szNum)
end

function UICharacterPendantPublicPage:SetLabelAccessory(szName)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetString(scriptPublic.LabelAccessory, szName)
end

function UICharacterPendantPublicPage:SetImgAccessoryIcon(szFrame)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetSpriteFrame(scriptPublic.ImgAccessoryIcon, szFrame)
end

function UICharacterPendantPublicPage:SetImgTitle(szFrame)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetSpriteFrame(scriptPublic.ImgTitle, szFrame)
end

return UICharacterPendantPublicPage