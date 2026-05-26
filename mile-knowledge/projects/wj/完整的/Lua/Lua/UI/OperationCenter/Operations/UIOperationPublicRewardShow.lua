-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationPublicRewardShow
-- Date: 2026-04-15 17:13:50
-- Desc: ?
-- ---------------------------------------------------------------------------------
--WidgetPublicRewardShow
local UIOperationPublicRewardShow = class("UIOperationPublicRewardShow")

function UIOperationPublicRewardShow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIOperationPublicRewardShow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationPublicRewardShow:BindUIEvent()
    UIHelper.BindUIEvent(self.PageViewRewardItem, EventType.OnTurningPageView, function ()
        local nPageIndex = UIHelper.GetPageIndex(self.PageViewRewardItem)
        self:AutoFixPageView(nPageIndex + 1)
    end)

    for nIndex,toggle in ipairs(self.tbPointList) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                local nCurIndex = UIHelper.GetPageIndex(self.PageViewRewardItem)
                if nCurIndex ~= (nIndex - 1) then
                    UIHelper.ScrollToPage(self.PageViewRewardItem, nIndex-1, 0.25)
                end
            end
        end)
    end
end

function UIOperationPublicRewardShow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationPublicRewardShow:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationPublicRewardShow:UpdateInfo()
    self:UpdateWeaponInfo()
end


function UIOperationPublicRewardShow:UpdateWeaponInfo()
    self.tCurWeaponList = self:GetCurWeaponList()
    local nCount = #self.tCurWeaponList
    for nIndex, togglePoint in ipairs(self.tbPointList) do
        local bVisable = nIndex <= nCount
        UIHelper.SetVisible(togglePoint, bVisable)
        if bVisable then
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, togglePoint)
        end
    end

    for nIndex, tbWeaponInfo in ipairs(self.tCurWeaponList) do
        local szMoblieImagePath = tbWeaponInfo.szMoblieImagePath or ""
        local dwWeaponIndex = tbWeaponInfo.dwWeaponIndex
        UIHelper.PageViewAddPage(self.PageViewRewardItem, PREFAB_ID.WidgetPublicRewardPicture, szMoblieImagePath, dwWeaponIndex)
    end

    Timer.AddFrame(self, 1, function ()
        local nLastIndex = math.max(0, #self.tCurWeaponList - 1)
        UIHelper.SetPageIndex(self.PageViewRewardItem, nLastIndex)
        self:AutoFixPageView(nLastIndex + 1)
    end)

    UIHelper.SetScrollViewMouseWheelEnabled(self.PageViewRewardItem, false)
end

function UIOperationPublicRewardShow:GetCurWeaponList()
    if not g_pClientPlayer then
        return
    end

    local dwMKungFuID = g_pClientPlayer.GetActualKungfuMountID()    --当前心法
    local tAllWeaponList = Table_GetOrangeWeaponInfoByForceID(g_pClientPlayer.dwForceID)    --所有武器
    local OtherWeaponList = Table_GetOrangeWeaponInfoByForceID(0)
    for i = 1, #OtherWeaponList do
        table.insert(tAllWeaponList, OtherWeaponList[i])
    end
    if dwMKungFuID == 10145 then
        dwMKungFuID = 10144
    end
    local nLevel = ShenBingUpgradeMgr.DEFAULT_LEVEL

    local tRes = {}
    for _, v in pairs(tAllWeaponList) do
        if v.dwMobileMKungFuID == dwMKungFuID and nLevel == v.nLevel then
            table.insert(tRes, v)
        end
        if v.dwMKungFuID == dwMKungFuID and nLevel == v.nLevel then
            table.insert(tRes, v)
        end
    end

    table.sort(tRes, function (a, b)
        if a.nStage ~= b.nStage then
            return a.nStage < b.nStage
        end
        return a.dwID < b.dwID
    end)

    return tRes
end

function UIOperationPublicRewardShow:AutoFixPageView(index)
    for nIndex, togglePoint in ipairs(self.tbPointList) do
        local bSelected = nIndex == index
        if bSelected then
            self:UpdatePageRewardInfo(nIndex)
        end
        UIHelper.SetSelected(togglePoint, bSelected)
    end
end

function UIOperationPublicRewardShow:UpdatePageRewardInfo(nIndex)
    local tbWeaponInfo = self.tCurWeaponList[nIndex]
    if not tbWeaponInfo then
        return
    end

    local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tbWeaponInfo.dwWeaponIndex)
    local szName = UIHelper.GBKToUTF8(tItemInfo.szName)
    local szStage = FormatString(g_tStrings.STR_WEAPON_UPGRADE_CURSTAGE, g_tStrings.STR_NUMBER[tbWeaponInfo.nStage])
    UIHelper.SetString(self.LabeName, szName)
    UIHelper.SetString(self.LabeLevel, szStage)
end

return UIOperationPublicRewardShow