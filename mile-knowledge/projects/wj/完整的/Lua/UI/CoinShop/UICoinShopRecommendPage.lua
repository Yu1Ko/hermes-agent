-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopRecommendPage
-- Date: 2026-03-26 10:24:38
-- Desc: 商城推荐穿搭浮窗页面
-- ---------------------------------------------------------------------------------

local FACE_LIST_PAGE_SIZE = 12

local UICoinShopRecommendPage = class("UICoinShopRecommendPage")

function UICoinShopRecommendPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    ShareCodeData.ApplyAccountConfig(false, SHARE_DATA_TYPE.EXTERIOR, true)
end

function UICoinShopRecommendPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopRecommendPage:BindUIEvent()
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupCardList, true)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        self:RequestRecommendList()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
        Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, false)
    end)
end

function UICoinShopRecommendPage:RegEvent()
    Event.Reg(self, EventType.OnGetShareStationRecommendList, function(nDataType, tData)
        if not self.bInit then return end
        if nDataType ~= SHARE_DATA_TYPE.EXTERIOR then
            return
        end
        self.tRecommendList = tData
        self:UpdateInfo()
    end)
end

function UICoinShopRecommendPage:UnRegEvent()
    Event.UnRegAll(self)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--- 构建 tExteriorList 的稳定哈希 key，用于去重
local function BuildExteriorListKey(tExteriorList)
    if not tExteriorList then
        return ""
    end
    local tbKeys = {}
    for nSub, tIds in pairs(tExteriorList) do
        local tbSorted = {}
        if type(tIds) == "table" then
            for _, dwID in ipairs(tIds) do
                table.insert(tbSorted, dwID)
            end
            table.sort(tbSorted)
        end
        table.insert(tbKeys, tostring(nSub) .. ":" .. table.concat(tbSorted, ","))
    end
    table.sort(tbKeys)
    return table.concat(tbKeys, "|")
end

--- 外部统一入口：打开推荐面板
-- @param tExteriorList table  { [nSub] = { dwID, ... }, ... }
-- @param szTitleName   string 标题名（由调用方计算传入）
function UICoinShopRecommendPage:Open(tExteriorList, szTitleName)
    if not tExteriorList or table.is_empty(tExteriorList) then
        self:Close()
        return
    end

    local szNewKey = BuildExteriorListKey(tExteriorList)
    if szNewKey == self.m_szExteriorKey and self.tRecommendList then
        return
    end

    self.m_szExteriorKey = szNewKey
    self.m_tExteriorList = tExteriorList
    self.tRecommendList = nil
    self.m_szTitleName = szTitleName or ""

    UIHelper.SetVisible(self._rootNode, true)
    if self.LabelMycaseTitle then
        local szDisplayTitle = (szTitleName and szTitleName ~= "") and szTitleName or UIHelper.UTF8ToGBK("穿搭作品")
        UIHelper.SetString(self.LabelMycaseTitle, UIHelper.GBKToUTF8(szDisplayTitle), 13)
    end
    if self.LabelDescibe01 then
        UIHelper.SetString(self.LabelDescibe01, "数据获取中")
    end

    if string.is_nil(szTitleName) then
        UIHelper.SetString(self.LabelDescibe01, "数据获取中")
    end

    self:RequestRecommendList()
    self:UpdateInfo()
end

--- 请求推荐列表数据
function UICoinShopRecommendPage:RequestRecommendList()
    if not self.m_tExteriorList then
        return
    end

    ShareCodeData.GetPackRecommendList(false, self.m_tExteriorList)
end

--- 关闭推荐面板
function UICoinShopRecommendPage:Close()
    self.m_szExteriorKey = nil
    self.m_tExteriorList = nil
    self.tRecommendList = nil
    UIHelper.SetVisible(self._rootNode, false)
end

--- 是否正在显示
function UICoinShopRecommendPage:IsShow()
    return UIHelper.IsVisible(self._rootNode)
end

--- 随机抽取指定数量元素
local function GetRandomTable(tbSource, nCount)
    if not tbSource or nCount <= 0 then
        return {}
    end
    local tbTemp = clone(tbSource) or {}
    local tbList = {}
    local nMax = math.min(nCount, #tbTemp)
    for i = 1, nMax do
        local nRand = math.random(1, #tbTemp)
        table.insert(tbList, tbTemp[nRand])
        table.remove(tbTemp, nRand)
    end
    return tbList
end

--- 打开面板时先显示 empty 状态（等待数据到达前的初始态）
function UICoinShopRecommendPage:ShowEmpty()
    self.tRecommendList = nil
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.BtnChange, false)
    UIHelper.SetString(self.LabelMycaseTitle, "穿搭作品")
    if self.LabelDescibe01 then
        UIHelper.SetString(self.LabelDescibe01, "暂无穿搭作品\n可前往设计站查看更多作品")
    end

    self:UpdateInfo()
end

--- 渲染推荐卡片列表
function UICoinShopRecommendPage:UpdateInfo()
    if self.ToggleGroupCardList then
        UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupCardList)
    end
    UIHelper.RemoveAllChildren(self.ScrollCardList)
    UIHelper.ScrollViewSetupArrow(self.ScrollCardList, self.WidgetArrowDown)

    -- 先隐藏，等数据判断后再决定是否显示
    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetVisible(self.WidgetHint, false)

    if not self.tRecommendList then
        -- 数据未到达，显示空态，隐藏向下滑提示
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetArrowDown, false)
        return
    end

    local bEmpty = true
    local tbRandomList = GetRandomTable(self.tRecommendList, FACE_LIST_PAGE_SIZE)

    for i = 1, #tbRandomList do
        local tData = tbRandomList[i]
        if tData then
            bEmpty = false
            local nPrefabID = PREFAB_ID.WidgetFaceStationFaceCell
            if tData.nPhotoSizeType and tData.nPhotoSizeType == SHARE_PHOTO_SIZE_TYPE.HORIZONTAL then
                nPrefabID = PREFAB_ID.WidgetFaceStationFaceLandscapeCell
            end

            local script = UIHelper.AddPrefab(nPrefabID, self.ScrollCardList)
            script:OnEnter(SHARE_DATA_TYPE.EXTERIOR, tData, true)
            script:SetBatchSelecte(false)
            script:SetSelectedCallback(function(bSelected)
                if bSelected then
                    local bNeedToSetSkip = false
                    local function fnConfirm()
                        local tFilterExterior = {}
                        if tData.tFilterData then
                            for nSub, nValue in pairs(tData.tFilterData) do
                                tFilterExterior[nSub] = { nValue }
                            end
                        end
                        ShareStationData.tbEventLinkInfo = {
                            nDataType = SHARE_DATA_TYPE.EXTERIOR,
                            szShareCode = tData.szShareCode,
                            tFilterExterior = tFilterExterior,
                        }
                        ShareStationData.OpenShareStation(SHARE_DATA_TYPE.EXTERIOR)
                        if bNeedToSetSkip then
                            Storage.CoinShopRecommend.bSkipShareConfirm = true
                            Storage.CoinShopRecommend.Dirty()
                        end
                    end
                    local function fnCancel()
                        ShareStationData.tbEventLinkInfo = nil
                        -- 取消前往设计站时清除卡片高亮
                        script:SetSelected(false)
                    end

                    if Storage.CoinShopRecommend.bSkipShareConfirm then
                        fnConfirm()
                    else
                        local szTitle = g_tStrings.COINSHOP_SHARE_STATION_PREVIEW_CONFIRM
                        local pView = UIHelper.ShowConfirm(szTitle, fnConfirm, fnCancel)
                        if pView then
                            pView:SetNoMorePromptsFunc(function(bSelected)
                                bNeedToSetSkip = bSelected
                            end)
                        end
                    end
                end
            end)
            if self.ToggleGroupCardList then
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupCardList, script.TogFaceCell)
            end
            UIHelper.SetVisible(script.WidgetPublic, false)
            UIHelper.SetVisible(script._rootNode, true)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollCardList)
    UIHelper.SetVisible(self.WidgetArrowDown, not bEmpty)
    UIHelper.ScrollViewSetupArrow(self.ScrollCardList, self.WidgetArrowDown)

    if self.WidgetEmpty then
        UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
        UIHelper.SetVisible(self.WidgetHint, not bEmpty)
    end

    if self.BtnChange then
        UIHelper.SetVisible(self.BtnChange, not bEmpty)
    end
    if self.LabelDescibe01 then
        UIHelper.SetString(self.LabelDescibe01, bEmpty and "暂无穿搭作品\n可前往设计站查看更多作品" or "")
    end
end


return UICoinShopRecommendPage