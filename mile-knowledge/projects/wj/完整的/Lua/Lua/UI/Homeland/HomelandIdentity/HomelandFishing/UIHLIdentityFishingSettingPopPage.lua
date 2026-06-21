-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHLIdentityFishingSettingPopPage
-- Date: 2024-02-29 10:58:51
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIHLIdentityFishingSettingPopPage = class("UIHLIdentityFishingSettingPopPage")

function UIHLIdentityFishingSettingPopPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHLIdentityFishingSettingPopPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHLIdentityFishingSettingPopPage:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewMessageContent01, false)
    UIHelper.SetTouchDownHideTips(self.BtnCloseRight, false)
    UIHelper.SetTouchDownHideTips(self.TogAoutSell01, false)
    UIHelper.SetTouchDownHideTips(self.TogAoutSell02, false)
    UIHelper.BindUIEvent(self.TogAoutSell01, EventType.OnClick, function(btn)
        local nDisplayType = UIHelper.GetSelected(self.TogAoutSell01) and GameSettingType.PlayDisplay.HideAll or GameSettingType.PlayDisplay.All
        APIHelper.SetPlayDisplay(nDisplayType, true)
    end)

    UIHelper.BindUIEvent(self.TogAoutSell02, EventType.OnClick, function(btn)
        APIHelper.SetNpcDisplay()
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
		Event.Dispatch(EventType.HideAllHoverTips)
    end)
end

function UIHLIdentityFishingSettingPopPage:RegEvent()
    Event.Reg(self, "REMOTE_HOME_FISH_EVENT", function()
        self:UpdateFishShieldInfo()
    end)
end

function UIHLIdentityFishingSettingPopPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function ParsePriority(tValue)
    local tRes = {}
    for i, v in pairs(tValue) do
        tRes[i] = tonumber(v)
    end
    return tRes
end

local function ParseExtPriority(tValue)
    local tRes = {}
    local tExtList = ParsePriority(tValue)
    local tbPriorityInfo = Table_GetAllHLIdentityPriority()
    for _, v in pairs(tExtList) do
        local tInfo
        for _, tbPriority in pairs(tbPriorityInfo) do
            if tbPriority.dwID == v then
                tInfo = tbPriority
                break
            end
        end

        if tInfo and tInfo.nType then
            if not tRes[tInfo.nType] then
                tRes[tInfo.nType] = {}
            end
            table.insert(tRes[tInfo.nType], tInfo)
        end
    end
    return tRes
end

local function _GetFishIdentityExtInfo()
    local tbList = Table_GetHLIdentity(HLIDENTITY_TYPE.FISH)
    local tbExtInfo = ParseExtPriority(SplitString(tbList.szExtPriority, ";"))

    return tbExtInfo
end

local function _GetFishIdentityData()
    local tbIdentityData = {}
    for _, v in pairs(GDAPI_GetHLIdentityInfo()) do
        if v.dwID == HLIDENTITY_TYPE.FISH then
            if v.tExtInfo then
                for _, tData in pairs(v.tExtInfo) do
                    tbIdentityData[tData.dwID] = tData
                end
            end
        end
    end

    return tbIdentityData
end

function UIHLIdentityFishingSettingPopPage:UpdateInfo()
    UIHelper.SetSelected(self.TogAoutSell01, APIHelper.MainCityLeftBottomPlayDisplayCheck())
    UIHelper.SetSelected(self.TogAoutSell02, APIHelper.NpcDisplayCheck())
    self:UpdateFishShieldInfo()

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMessageContent01)
end

function UIHLIdentityFishingSettingPopPage:UpdateFishShieldInfo()
    UIHelper.RemoveAllChildren(self.LayoutSkin)
    local tbInfo = _GetFishIdentityExtInfo()
    local tbData = _GetFishIdentityData()
    for index, v in pairs(tbInfo[1]) do
        local tExtData = tbData[v.dwID]
        v.bLock = tExtData.bLock
        v.bCanUse = tExtData.bCanUse
        v.bCurUse = tExtData.bCurUse

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.LayoutSkin)
        self:InitIcon(script, v)
    end

    UIHelper.LayoutDoLayout(self.LayoutSkin)
end


function UIHLIdentityFishingSettingPopPage:InitIcon(icon, tInfo)
    local nIconID = tInfo.nIconID
    local szTitle = UIHelper.GBKToUTF8(tInfo.szName)
    local szDesc = UIHelper.GBKToUTF8(tInfo.szDescMB)
    local szLockDesc = UIHelper.GBKToUTF8(tInfo.szLockDesc)
    szDesc = ParseTextHelper.ParseNormalText(szDesc, false)
    if not string.is_nil(szLockDesc) then
        szLockDesc = ParseTextHelper.ParseNormalText(szLockDesc, false)
        szDesc = szDesc.."\n"
    end

    UIHelper.SetVisible(icon.ImgIcon, false)
    UIHelper.RemoveAllChildren(icon.WidgetContainer)

    UIHelper.SetString(icon.LabelName, UIHelper.LimitUtf8Len(szTitle, 4))
    UIHelper.SetString(icon.LabelLevel, "未解锁")
    local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, icon.WidgetContainer) assert(itemScript)
    itemScript:OnInitWithIconID(nIconID)
    UIHelper.SetScale(itemScript._rootNode, 0.6, 0.6)
    itemScript:SetSelectEnable(false)

    UIHelper.SetVisible(icon.ImgSelect, tInfo.bCurUse)
    UIHelper.SetVisible(icon.Locked, tInfo.bLock)
    UIHelper.BindUIEvent(icon.BtnQuickOperation, EventType.OnClick, function ()
        if not tInfo.bLock and not tInfo.bCurUse and tInfo.bCanUse then
            if not HomelandIdentity.CanChangeManSkin() then -- 垂钓客换鱼竿
                TipsHelper.ShowNormalTip(g_tStrings.STR_HAVE_CD)
                return
            end
            RemoteCallToServer("On_HomeLand_FishManSkin", tInfo.dwID)
        end
    end)
end

return UIHLIdentityFishingSettingPopPage