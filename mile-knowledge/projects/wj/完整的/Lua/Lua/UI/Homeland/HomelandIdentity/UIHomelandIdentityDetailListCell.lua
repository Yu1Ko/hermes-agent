-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityDetailListCell
-- Date: 2024-01-18 20:02:42
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIHomelandIdentityDetailListCell = class("UIHomelandIdentityDetailListCell")

function UIHomelandIdentityDetailListCell:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self:UpdateInfo()
end

function UIHomelandIdentityDetailListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityDetailListCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.ScrollviewListCell, false)
end

function UIHomelandIdentityDetailListCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.iconSelected and self.iconSelected.SetSelected then
            self.iconSelected:SetSelected(false)
        end
    end)
end

function UIHomelandIdentityDetailListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityDetailListCell:UpdateInfo()
    local tData = self.tData
    for _, tInfo in ipairs(tData) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.ScrollviewListCell)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
        self:InitIcon(script, tInfo)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollviewListCell)
    UIHelper.ScrollToTop(self.ScrollviewListCell)
end

function UIHomelandIdentityDetailListCell:InitIcon(icon, tInfo)
    local nIconID = tInfo.nIconID
    local szReward = tInfo.szReward
    local szTitle = UIHelper.GBKToUTF8(tInfo.szName)
    local szDesc = UIHelper.GBKToUTF8(tInfo.szDescMB)
    local szLockDesc = UIHelper.GBKToUTF8(tInfo.szLockDesc)
    szTitle = string.format("<color=%s>%s</c>\n", tInfo.bLock and "#FF7676" or "#95FF95", szTitle)
    szDesc = ParseTextHelper.ParseNormalText(szDesc, false)
    if not string.is_nil(szLockDesc) then
        szLockDesc = ParseTextHelper.ParseNormalText(szLockDesc, false)
        szDesc = szDesc.."\n"
    end

    if not string.is_nil(szReward) then
        local tbItemInfo = string.split(szReward, "_")
        icon:OnInitWithTabID(tonumber(tbItemInfo[1]), tonumber(tbItemInfo[2]))
    else
        icon:OnInitWithIconID(nIconID)
        icon:SetItemQualityBg(2)
    end

    icon:ShowNowIcon(tInfo.bCurUse)
    icon:ShowLockIcon(tInfo.bLock)
    icon:SetTouchDownHideTips(false)
    icon:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
    icon:SetClickCallback(function ()
        self.iconSelected = icon
        local nX,nY = UIHelper.GetWorldPosition(icon._rootNode)
        local nSizeW,nSizeH = UIHelper.GetContentSize(icon._rootNode)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetPublicLabelTips,nX-nSizeW+50,nY+nSizeH)
        scriptTips:OnEnter(szTitle..szDesc..szLockDesc)

        if not tInfo.bLock and not tInfo.bCurUse and tInfo.bCanUse then
            if not HomelandIdentity.CanChangeManSkin() then -- 垂钓客换鱼竿
                TipsHelper.ShowNormalTip(g_tStrings.STR_HAVE_CD)
                return
            end
            RemoteCallToServer("On_HomeLand_FishManSkin", tInfo.dwID)
        end
    end)
end


return UIHomelandIdentityDetailListCell