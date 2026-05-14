-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMapEntranceLKx
-- Date: 2023-04-13 20:01:27
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nFrameToSpritFrame = {
    "UIAtlas2_LangKeXing_VagabondGroup_LKXbeast",
    "UIAtlas2_LangKeXing_VagabondGroup_LKXcorpse",
    "UIAtlas2_LangKeXing_VagabondGroup_LKXjapan",
    "UIAtlas2_LangKeXing_VagabondGroup_LKXpoison",
    "UIAtlas2_LangKeXing_VagabondGroup_LKXredclothes",
    "UIAtlas2_LangKeXing_VagabondGroup_LKXspirit",
    "UIAtlas2_LangKeXing_VagabondGroup_LKXtianyi",
    "UIAtlas2_LangKeXing_VagabondGroup_LKXwolftooth",
}


local UIWidgetMapEntranceLKx = class("UIWidgetMapEntranceLKx")

function UIWidgetMapEntranceLKx:OnEnter(tbMapInfo, ToggleGroup, bSelect, scriptReward)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMapInfo = tbMapInfo
    self.ToggleGroup = ToggleGroup
    self.bSelect = bSelect
    self.szName = Table_GetMapName(self.tbMapInfo.nMapID)
    self.scriptReward = scriptReward
    self:UpdateInfo()
end

function UIWidgetMapEntranceLKx:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMapEntranceLKx:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.scriptReward:SetMapID(self.tbMapInfo.nMapID)
        end
    end)

    UIHelper.BindUIEvent(self.TogInfo, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:OpenTips(PREFAB_ID.WidgetMapTipsLKX, self.szName, UIHelper.GBKToUTF8(self.tbMapInfo.szTip), nil, self.TogInfo)
        else
            self:CloseCurTips()
        end
    end)
end

function UIWidgetMapEntranceLKx:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    -- Event.Reg(self, EventType.HideAllHoverTips, function()
    --     self:CloseCurTips()
    -- end)
end

function UIWidgetMapEntranceLKx:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMapEntranceLKx:UpdateInfo()

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.szName))
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self._rootNode)

    local szImagePath = string.gsub(self.tbMapInfo.szImgPath, "UITex", "Tga")
    UIHelper.SetTexture(self.ImgBg, szImagePath)
    UIHelper.SetSwallowTouches(self.TogInfo, true)

    local tbTips = self.tbMapInfo.tTips

    self:UpdateIconItem(tbTips.tIconItem or {})
    
    self:UpdateProp(tbTips.tProp or {})

    self:UpdateBuff(tbTips.tBuff or {})

    UIHelper.LayoutDoLayout(self.LayoutReward)

    if self.bSelect then 
        self.scriptReward:SetMapID(self.tbMapInfo.nMapID)
    end

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(self.tbMapInfo.nMapID)
    scriptDownload:OnInitWithPackID(nPackID)
end

function UIWidgetMapEntranceLKx:UpdateIconItem(tbData)

    UIHelper.SetVisible(self.RewardGoods01, #tbData ~= 0)
    if not tbData then return end

    for _, v in ipairs(tbData) do
        local tLine = Table_GetVagabondCrossMapTip(v.nID)
        local szImagePath = string.gsub(tLine.szIconPath, "UITex", "Tga")
        UIHelper.SetSpriteFrame(self.ImgIcon, nFrameToSpritFrame[tLine.nFrame])
        UIHelper.SetString(self.NodeName01, v.szDes or UIHelper.GBKToUTF8(tLine.szDes))
    end
end

function UIWidgetMapEntranceLKx:UpdateProp(tbData)

    UIHelper.SetVisible(self.RewardGoods02, #tbData ~= 0)
    if not tbData then return end

    for _, v in ipairs(tbData) do
        local KItemInfo = GetItemInfo(v.nType, v.nID)
        local szName = v.szDes or UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(KItemInfo))
        UIHelper.SetString(self.NodeName02, szName)
        self.scriptViewBuffIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.RewardGoods02)
        self.scriptViewBuffIcon:OnInitWithTabID(v.nType, v.nID)
        self.scriptViewBuffIcon:SetClickCallback(function(nTabType, nTabID)
            if nTabType and nTabID then
                self:OpenTips(PREFAB_ID.WidgetItemTip, nTabType, nTabID, self.scriptViewBuffIcon)
            else
                self:CloseCurTips()
            end
        end)
    end
end

function UIWidgetMapEntranceLKx:UpdateBuff(tbData)

    UIHelper.SetVisible(self.RewardGoods03, tbData and #tbData ~= 0)
    if not tbData then return end

    for _, v in ipairs(tbData) do
        local szName = v.szDes or UIHelper.GBKToUTF8(Table_GetBuffName(v.nID, v.nLevel))
        UIHelper.SetString(self.NodeName03, szName)
        self.scriptViewPropIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.RewardGoods03)
        local tbBuff = Table_GetBuff(v.nID, v.nLevel)
        self.scriptViewPropIcon:OnInitWithIconID(tbBuff.dwIconID)
        self.scriptViewPropIcon:SetSelectChangeCallback(function(nItemID, bSelected, nBox, nIndex)
            if bSelected then
                local szTip = ParseTextHelper.ParseNormalText(UIHelper.GetBuffTip(v.nID, v.nLevel))
                self:OpenTips(PREFAB_ID.WidgetMapTipsLKX, UIHelper.UTF8ToGBK(szName), szTip, self.scriptViewPropIcon, nil)
            else
                self:CloseCurTips()
            end
        end)
    end
end


function UIWidgetMapEntranceLKx:OpenTips(nPrefabID, ...)
    -- self:CloseCurTips()
    -- self.nCurPrefabID = nPrefabID
    -- if nPrefabID == PREFAB_ID.WidgetItemTip then
    --     local tbArgs = {...}
    --     local nTabType = tbArgs[1]
    --     local nTabID = tbArgs[2]
    --     self.scriptViewItemIcon = tbArgs[3] and tbArgs[3] or nil
    --     self.tips, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(nPrefabID, self._rootNode)
    --     self.tipsScriptView:OnInitWithTabID(nTabType, nTabID)
    --     self.tipsScriptView:SetBtnState({})
    -- else
    --     local tbArgs = {...}
    --     local szTitle = tbArgs[1]
    --     local szDesc = tbArgs[2] 
    --     self.scriptViewItemIcon = tbArgs[3] and tbArgs[3] or nil
    --     self.CurToggle = tbArgs[4] or nil
    --     self.tips, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetMapTipsLKX, self._rootNode, UIHelper.GBKToUTF8(szTitle), szDesc)
    -- end
    self.scriptReward:OpenTips(nPrefabID, self._rootNode, ...)
end

function UIWidgetMapEntranceLKx:CloseCurTips()
    -- if self.nCurPrefabID then
    --     TipsHelper.DeleteHoverTips(self.nCurPrefabID)
    --     if self.scriptViewItemIcon then
    --         self.scriptViewItemIcon:RawSetSelected(false)
    --     end
    --     if self.CurToggle then
    --         UIHelper.SetSelected(self.CurToggle, false, false)
    --     end
    --     self.nCurPrefabID = nil
    -- end
    self.scriptReward:CloseCurTips()
end


return UIWidgetMapEntranceLKx