-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelChooseLv
-- Date: 2023-04-10 15:49:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelChooseLv = class("UIPanelChooseLv")

function UIPanelChooseLv:OnEnter(tbDataInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbDataInfo then
        self.tbDataInfo = tbDataInfo
        self:UpdateInfo()
        self:AutoClose()

        --资源下载Widget
        local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
        local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.LKX)
        scriptDownload:OnInitWithPackIDList(tPackIDList)
    end

    UIHelper.AddPrefab(PREFAB_ID.WidgetSkillConfiguration, self.WidgetSkillConfiguration)
end

function UIPanelChooseLv:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelChooseLv:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGoon, EventType.OnClick, function(btn)
        -- 地图资源下载检测拦截
        local tMapIDList = self:GetDownloadMapIDList()
        if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, true, "浪客行") then
            return
        end
        MapMgr.BeforeTeleport()
        RemoteCallToServer("On_LangKeXing_ReBegin", VagabondData.GetCurrentID())
        self:CloseItemTip()
    end)

    UIHelper.BindUIEvent(self.BtnStart, EventType.OnClick, function(btn)
        -- 地图资源下载检测拦截
        local tMapIDList = self:GetDownloadMapIDList()
        if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, true, "浪客行") then
            return
        end
        MapMgr.BeforeTeleport()
        RemoteCallToServer("On_LangKeXing_Begin")
        self:CloseItemTip()
    end)

    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function(btn)
        ShopData.OpenSystemShopGroup(1, 1222)
    end)

    UIHelper.BindUIEvent(self.BtnFindGroup, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, 267)
    end)
end

function UIPanelChooseLv:RegEvent()
    Event.Reg(self, EventType.OnSelectTogGroupLeft, function(dwID)
        self:SetCurrentID(dwID)
    end)
    
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:CloseItemTip()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseItemTip()
    end)

end

function UIPanelChooseLv:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelChooseLv:UpdateInfo()
    self:UpdateInfo_TogGroupLeft()
    self:UpdateInfo_CurrentTypeInfo()
    self:UpdateInfo_TipsLableLeft()
    self:UpdateInfo_Currency()
end

function UIPanelChooseLv:UpdateInfo_Currency()
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency,
			5, 85502, true)
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end

function UIPanelChooseLv:UpdateInfo_TipsLableLeft()
    -- UIHelper.SetRichText(self.RichTextNum, "<color=#FFE26E>"..self.tbDataInfo.nLeftCanGet.."</color>".."<color=#AED9E0>"..g_tStrings.STR_VAFRANT_NUM.."</color>")
    UIHelper.SetString(self.LabelGetTips, string.format("（本周还可获得浪客笺：%s%s）", tostring(self.tbDataInfo.nLeftCanGet), g_tStrings.STR_VAFRANT_NUM))
end

function UIPanelChooseLv:UpdateInfo_TogGroupLeft()
    for nIndex, tbInfo in ipairs(self.tbDataInfo.tInfo) do
        local toggle = self.tbTogGroupLeft[nIndex]
        local scriptView = UIHelper.GetBindScript(toggle)
        scriptView:OnEnter(tbInfo)
    end
end

function UIPanelChooseLv:UpdateInfo_CurrentTypeInfo()
    local tbCurDataInfo = VagabondData.GetCurDataInfo()
    self:UpdateInfo_CurrentTypeTitle(tbCurDataInfo)
    self:UpdateInfo_CurrentTypeCondition(tbCurDataInfo)
    self:UpdateInfo_CurrentTypeIntroduce(tbCurDataInfo)

    UIHelper.ScrollViewDoLayout(self.ScrollViewDetail)
    UIHelper.ScrollToTop(self.ScrollViewDetail)

    self:UpdateInfo_CurrentTypeAward(tbCurDataInfo)
    self:UpdateInfo_ButtonState(tbCurDataInfo)
end

function UIPanelChooseLv:UpdateInfo_CurrentTypeTitle(tbCurDataInfo)
    local szText = tbCurDataInfo.szTitle..tbCurDataInfo.szSubTitle
    UIHelper.SetString(self.LabelTitle09, UIHelper.GBKToUTF8(szText))
end

function UIPanelChooseLv:UpdateInfo_CurrentTypeCondition(tbCurDataInfo)
    local szText = ""
    for index, szLimitName in ipairs(tbCurDataInfo.tLimit) do
        if index == 1 then
            szText = szText..g_tStrings.STR_LIMIT_DESC[szLimitName]
        else
            szText = szText.."\n"..g_tStrings.STR_LIMIT_DESC[szLimitName]
        end
    end
    szText = "<color=#AED9E0>"..szText.."</color>"
    UIHelper.SetRichText(self.RichTextTarget01, szText)
    UIHelper.LayoutDoLayout(self.LayoutTarget)
end

function UIPanelChooseLv:UpdateInfo_CurrentTypeIntroduce(tbCurDataInfo)
    local szText = "<color=#AED9E0>"..UIHelper.GBKToUTF8(tbCurDataInfo.szDesc).."</color>"
    UIHelper.SetRichText(self.RichTextDetail,szText)
    UIHelper.LayoutDoLayout(self.LayoutDetail)
end

function UIPanelChooseLv:UpdateInfo_CurrentTypeAward(tbCurDataInfo)
    UIHelper.RemoveAllChildren(self.ScrollViewAward)
    for index, tAwardInfo in ipairs(tbCurDataInfo.tAward) do
        local nTabType = tAwardInfo[1]
		local nIndex = tAwardInfo[2]
		local nStackNum = tAwardInfo[3]
        local ItemInfo = GetItemInfo(nTabType, nIndex)
        local szItemName = ItemData.GetItemNameByItemInfo(ItemInfo, nStackNum)
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.ScrollViewAward, UIHelper.GBKToUTF8(szItemName), nStackNum, nTabType, nIndex)
        scriptView:SetClickCallback(function(nTabType, nItemIndex)
            if nTabType and nItemIndex then
                self:ShowItemTip(nTabType, nItemIndex, scriptView)
            else
                self:CloseItemTip()
            end
        end)
        scriptView:SetIconSwallowTouches(true)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewAward)
    UIHelper.ScrollToLeft(self.ScrollViewAward)
    UIHelper.SetSwallowTouches(self.ScrollViewAward, false)
end

function UIPanelChooseLv:UpdateInfo_ButtonState(tbCurDataInfo)
    UIHelper.SetVisible(self.GoonAnchorBottom, tbCurDataInfo.dwID == VagabondData.GetSaveSelectionID())
    UIHelper.LayoutDoLayout(self.LayoutBottom)
end

function UIPanelChooseLv:ShowItemTip(nTabType, nItemIndex, scriptView)
    if not self.scriptItemTip then
        -- self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
        self.tips, self.scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptView._rootnode)
    end
    self.scriptItemTip:OnInitWithTabID(nTabType, nItemIndex)
    self.scriptItemTip:SetBtnState({})
    self.scriptIconView = scriptView
end

function UIPanelChooseLv:CloseItemTip()
    if self.scriptItemTip then
        UIHelper.RemoveAllChildren(self.WidgetItemTip)
        self.scriptIconView:RawSetSelected(false)
        self.scriptItemTip = nil
        self.scriptIconView = nil
    end
end


function UIPanelChooseLv:SetCurrentID(dwCurrentID)
    VagabondData.SetCurrentID(dwCurrentID)
    self:UpdateInfo_CurrentTypeInfo()
end

function UIPanelChooseLv:AutoClose()
    if self.nCloseTimer then 
        Timer.DelTimer(self, self.nCloseTimer)
    end
    self.nCloseTimer = Timer.AddFrameCycle(self, 1, function()
        local pPlayer = g_pClientPlayer
        local pTarget
        local nTargetType = self.tbDataInfo.nTargetType
        local nTargetID = self.tbDataInfo.nTargetID
        if nTargetType == TARGET.NPC then
            pTarget = GetNpc(nTargetID)
        elseif nTargetType == TARGET.DOODAD then
            pTarget = GetDoodad(nTargetID)
        end

        if not pPlayer or (nTargetID and (not pTarget or not pTarget.CanDialog(pPlayer))) then
            UIMgr.Close(self)
        end
    end)
end

function UIPanelChooseLv:GetDownloadMapIDList()
    local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.LKX)
    local tMapIDList = {}
    for _, nPackID in ipairs(tPackIDList) do
        local _, nMapID = PakDownloadMgr.IsMapRes(nPackID)
        if nMapID and not table.contain_value(tMapIDList, nMapID) then
            table.insert(tMapIDList, nMapID)
        end
    end
    return tMapIDList
end

return UIPanelChooseLv