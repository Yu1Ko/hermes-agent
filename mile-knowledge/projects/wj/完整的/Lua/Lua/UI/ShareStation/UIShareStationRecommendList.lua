-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationRecommendList
-- Date: 2025-12-16 14:50:35
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nCoolDownTime = 10 -- s
local FACE_LIST_PAGE_SIZE = 12 --每一页最多显示捏脸的数量
local UIShareStationRecommendList = class("UIShareStationRecommendList")

function UIShareStationRecommendList:OnEnter(bIsLogin, nDataType, tFilter)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bNeedUpdateInfo = true
    self.bIsLogin = bIsLogin
    self.nDataType = nDataType
    self.tFilter = tFilter
    self:Init()
    ShareCodeData.ApplyAccountConfig(bIsLogin, nDataType, true)
end

function UIShareStationRecommendList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationRecommendList:BindUIEvent()
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupCardList, true)
    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function(btn)
        self:UpdateInfo()
    end)
end

function UIShareStationRecommendList:RegEvent()
    Event.Reg(self, EventType.OnGetShareStationRecommendList, function(nDataType, tData)
        if nDataType ~= self.nDataType then
            return
        end
        self.tRecommendList = tData
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnGetShareStationUploadConfig, function (nDataType)
        if self.bNeedUpdateInfo then
            Timer.Add(self, 0.1, function ()
                ShareCodeData.ApplyCollectList(self.bIsLogin, self.nDataType)
                -- self:UpdateInfo()
            end)
        end
    end)
end

function UIShareStationRecommendList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIShareStationRecommendList:Init()
    self.tRecommendList = nil
    ShareCodeData.GetRecommendList(self.bIsLogin, self.nDataType, self.tFilter)
    self:UpdateInfo()
    UIHelper.SetString(self.LabelDescibe01, "数据获取中")
end

local _fnGetRandomTable = function(tbSource, nCount)
    local tbList = {}
    if not tbSource or nCount <= 0 then
        return tbList
    end

    local tbTemp = {}
    tbTemp = clone(tbSource) or {}

    -- 随机抽取 nCount 个元素
    local nMax = math.min(nCount, #tbTemp)
    for i = 1, nMax do
        local nRand = math.random(1, #tbTemp)
        table.insert(tbList, tbTemp[nRand])
        table.remove(tbTemp, nRand)
    end

    return tbList
end

function UIShareStationRecommendList:UpdateInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupCardList)
    UIHelper.RemoveAllChildren(self.ScrollCardList)
    UIHelper.SetVisible(self.WidgetEmpty, true)
    if not self.tRecommendList then
        return
    end

    local bEmpty = true
    local tbRandomList = _fnGetRandomTable(self.tRecommendList, FACE_LIST_PAGE_SIZE)

    for i = 1, #tbRandomList do
        local tData = tbRandomList[i]
        if tData then
            bEmpty = false
            local nPrefabID = PREFAB_ID.WidgetFaceStationFaceCell
            if tData.nPhotoSizeType and tData.nPhotoSizeType == SHARE_PHOTO_SIZE_TYPE.HORIZONTAL then
                nPrefabID = PREFAB_ID.WidgetFaceStationFaceLandscapeCell
            end

            if not self.tbScript then
                self.tbScript = {}
            end

            local script = UIHelper.AddPrefab(nPrefabID, self.ScrollCardList)
            script:OnEnter(self.nDataType, tData, true)
            script:SetBatchSelecte(false)
            script:SetSelectedCallback(function(bSelected)
                if bSelected then
                    local szShareCode = tData.szShareCode
                    ShareCodeData.ApplyData(self.bIsLogin, self.nDataType, szShareCode)
                end
            end)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupCardList, script.TogFaceCell)
            UIHelper.SetVisible(script.WidgetPublic, false)
            UIHelper.SetVisible(script._rootNode, true)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollCardList)
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.SetString(self.LabelDescibe01, bEmpty and "暂无推荐作品\n可前往设计站查看更多其他作品")
end


return UIShareStationRecommendList