-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeCollectionLevelView
-- Date: 2023-08-11 17:41:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeCollectionLevelView = class("UIHomeCollectionLevelView")
local DataModel = {}

function UIHomeCollectionLevelView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHomeCollectionLevelView:OnExit()
    self.bInit = false
end

function UIHomeCollectionLevelView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
       UIMgr.Close(self)
    end)
end

function UIHomeCollectionLevelView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeCollectionLevelView:UpdateInfo()
    local szAddr = g_tStrings.STR_HOMELAND_FURNITURE_SET_COLLECT_POINTS_LEVEL_TIP_1
    local nTotalCollectPoints = DataModel.GetTotalCollectPoints()
	local nCPLevel, nPointsInLevel, nDestPointsInLevel = DataModel.GetLevelValuesByTotalCollectPoints(nTotalCollectPoints)
    local tbString = SplitString(szAddr, "\n")
    for i, szLevel in ipairs(tbString) do
        if i == 1 then
            if nPointsInLevel then
                local nPercent = nPointsInLevel / nDestPointsInLevel * 100
                local nDestPoint = nDestPointsInLevel - nPointsInLevel
                local szRichTextContent = "<color=#d7f6ff>当前梓行点等级进度".."<color=#ffe26e>"..GetRoundedNumber(nPercent).."%</c>，</c><color=#d7f6ff>距离下一级还有".."<color=#ffe26e>"..nDestPoint.."分</c>。</c>"
                UIHelper.SetRichText(self.LabelTipInfo, szRichTextContent)
            else
                local szRichTextContent = "<color=#ffe56e"..g_tStrings.STR_HOMELAND_FURNITURE_SET_COLLECT_POINTS_LEVEL_TIP_2.."/c"
                UIHelper.SetRichText(self.LabelTipInfo, szRichTextContent)
            end
        else
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetFurnitureCollectLevelCell, self.ScrollViewLevel)
            scriptCell:OnEnter(szLevel)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLevel)
end

function DataModel.GetTotalCollectPoints()
	return GetClientPlayer().GetRemoteDWordArray(1076, 0)
end

function DataModel.GetLevelValuesByTotalCollectPoints(nTotalCollectPoints)
	local nCollectPointsLevel, nPointsInLevel, nDestPointsInLevel
	local nInitialPointsInLevel = 0
	local tUiTable = Table_GetAllFurnitureSetCollectPointsLevelInfo()
	local nRowCount = tUiTable:GetRowCount()
	for i = 2, nRowCount do
		local tLine = tUiTable:GetRow(i)
		local nDestPtsToNextLevel = tLine.nDestPtsToNextLevel
		if nDestPtsToNextLevel > nTotalCollectPoints then
			nCollectPointsLevel = tLine.nLevel
			nPointsInLevel = nTotalCollectPoints - nInitialPointsInLevel
			nDestPointsInLevel = nDestPtsToNextLevel - nInitialPointsInLevel
			break
		else
			nInitialPointsInLevel = nDestPtsToNextLevel
		end
	end
	
	-- 总分爆表的特殊情况处理
	if not nCollectPointsLevel then
		local tLastLine = tUiTable:GetRow(nRowCount)
		nCollectPointsLevel = tLastLine.nLevel
		nDestPointsInLevel = tLastLine.nDestPtsToNextLevel - tUiTable:GetRow(nRowCount - 1).nDestPtsToNextLevel
		nPointsInLevel = nDestPointsInLevel
	end
	
	return nCollectPointsLevel, nPointsInLevel, nDestPointsInLevel
end

return UIHomeCollectionLevelView