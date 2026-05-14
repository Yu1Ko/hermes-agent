-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopRewardsDetail
-- Date: 2023-08-24 16:31:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local function RegisterDetailTable()
    if not IsUITableRegister("RewardsShop_Detail") then
        RegisterUITable("RewardsShop_Detail", g_tRewardsShop_Detail.Path, g_tRewardsShop_Detail.Title)
    end
end

local function Table_GetIntroduce(dwID)
    RegisterDetailTable()

    local tLine = g_tTable.RewardsShop_Detail:Search(dwID)
    if not tLine then
        return
    end

    tLine.tPackageInfo = SplitString(tLine.szPackageInfo, "|")
    tLine.szPackageInfo = nil

    tLine.tPackageName = SplitString(tLine.szPackageName, "|")
    tLine.szPackageName = nil
    return tLine
end

local UICoinShopRewardsDetail = class("UICoinShopRewardsDetail")

function UICoinShopRewardsDetail:OnEnter(dwID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwID = dwID
    self.nCurIndex = -1
    self:UpdateInfo()
end

function UICoinShopRewardsDetail:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopRewardsDetail:BindUIEvent()
    -- for i, tog in ipairs(self.tTogItem) do
    --     UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
    --         if bSelected then
    --             UIHelper.SetPageIndex(self.PageViewSpecialItem, i-1)
    --         end
    --     end)
    -- end

    UIHelper.BindUIEvent(self.PageViewSpecialItem, EventType.OnTurningPageView, function ()
        local index = UIHelper.GetPageIndex(self.PageViewSpecialItem)
        index = math.max(index, 0)
        self.nCurIndex = index + 1
        self:UpdatePageInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSwitchLeft, EventType.OnClick, function()
        self.nCurIndex = self.nCurIndex - 1
        UIHelper.SetPageIndex(self.PageViewSpecialItem, self.nCurIndex - 1)
        self:UpdatePageInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRight, EventType.OnClick, function()
        self.nCurIndex = self.nCurIndex + 1
        UIHelper.SetPageIndex(self.PageViewSpecialItem, self.nCurIndex - 1)
        self:UpdatePageInfo()
    end)

end

function UICoinShopRewardsDetail:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopRewardsDetail:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopRewardsDetail:UpdateInfo()
    local tInfo = Table_GetIntroduce(self.dwID)
    if not tInfo then return end
    local count = tonumber(tInfo.tPackageInfo[1]) or 0

    -- for i, tog in ipairs(self.tTogItem) do
    --     UIHelper.SetVisible(tog, i <= count)
    --     UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tog)
    --     UIHelper.SetTouchDownHideTips(tog, false)
    -- end
    -- UIHelper.LayoutDoLayout(self.TogGroupRewardItem)
    self.nCount = count
    UIHelper.SetString(self.LabelGroupNum, 1 .. "/" .. self.nCount)
    for i = 1, count do
        local script = UIHelper.PageViewAddPage(self.PageViewSpecialItem, PREFAB_ID.WidgetSpecialItemPic)
        local szPath = string.format("%s%d_%d.png", tInfo.szImagePath, 1, i)
        szPath = string.gsub(szPath, "ui\\Image", "Resource")
        szPath = string.gsub(szPath, "ui/Image", "Resource")
        UIHelper.SetTexture(script.ImgSpecialItemPic, szPath)
    end
    --UIHelper.SetTouchDownHideTips(self.PageViewSpecialItem, false)
    UIHelper.ScrollViewDoLayout(self.PageViewSpecialItem)
    UIHelper.SetTouchEnabled(self.PageViewSpecialItem, false)

    UIHelper.SetString(self.LabelSpecialTitle, UIHelper.GBKToUTF8(tInfo.tPackageName[1]))
    local szDesc = string.pure_text(UIHelper.GBKToUTF8(tInfo.szDesc))
    local tDesc = string.split(szDesc, "\n\n")
    UIHelper.SetString(self.LabelSpecialExplain, tDesc[1])
    UIHelper.SetString(self.LabelSpecialInfo, tDesc[2])

    UIHelper.ScrollViewDoLayout(self.ScrollViewSpecialContent)

    local scrollViewHeight = UIHelper.GetHeight(self.ScrollViewSpecialContent)
    local containerHeight = UIHelper.GetHeight(self.ScrollViewSpecialContent:getInnerContainer())
    if scrollViewHeight > containerHeight then
        UIHelper.SetHeight(self.ScrollViewSpecialContent, containerHeight)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSpecialContent)
    UIHelper.SetTouchDownHideTips(self.ScrollViewSpecialContent, false)
    UIHelper.LayoutDoLayout(self.WidgetAnchorContent)

    UIHelper.SetTouchDownHideTips(self.BtnClose, false)

    UIHelper.SetTouchDownHideTips(self.BtnSwitchLeft, false)
    UIHelper.SetTouchDownHideTips(self.BtnSwitchRight, false)
end

function UICoinShopRewardsDetail:UpdatePageInfo()
    UIHelper.SetString(self.LabelGroupNum, self.nCurIndex .. "/" .. self.nCount)
    UIHelper.SetButtonState(self.BtnSwitchLeft, self.nCurIndex <= 1 and BTN_STATE.Disable or BTN_STATE.Normal)
    UIHelper.SetButtonState(self.BtnSwitchRight, self.nCurIndex >= self.nCount and BTN_STATE.Disable or BTN_STATE.Normal)
end

return UICoinShopRewardsDetail