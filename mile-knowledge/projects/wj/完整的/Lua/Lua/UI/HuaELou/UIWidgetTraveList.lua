-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTraveList
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTraveList = class("UIWidgetTraveList")
function UIWidgetTraveList:OnEnter(tbTravelList)
    if not tbTravelList then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tbTravelList)
end

function UIWidgetTraveList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTraveList:BindUIEvent()

end

function UIWidgetTraveList:RegEvent()
    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
		local tbPoint = tbInfo.tPoint or { tbInfo.fX, tbInfo.fY, tbInfo.fZ }
		MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tbInfo.szNpcName), tbInfo.dwMapID, tbPoint)
		UIMgr.Open(VIEW_ID.PanelMiddleMap, tbInfo.dwMapID, 0)
		Event.Dispatch(EventType.HideAllHoverTips)
	end)
end

function UIWidgetTraveList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTraveList:UpdateInfo(tbTravelList)
    self.tbTravelList = tbTravelList
    local nCount = #self.tbTravelList
    local nLimitCount = 6

    UIHelper.RemoveAllChildren(self.ScrollViewActivityDetail)
    UIHelper.RemoveAllChildren(self.LayoutLeaveFor)
    UIHelper.SetVisible(self.FlexLayoutDetail, nCount > nLimitCount)
    UIHelper.SetVisible(self.FixedLayoutDetail, nCount <= nLimitCount)

    local parent = nCount > nLimitCount and self.ScrollViewActivityDetail or self.LayoutLeaveFor
    for nIndex, tbTravelInfo in ipairs(self.tbTravelList) do
        local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForBtn, parent, tbTravelInfo)
        if scriptBtn then
            UIHelper.SetTouchDownHideTips(scriptBtn.BtnLeaveFor, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutLeaveFor)
    UIHelper.ScrollViewDoLayout(self.ScrollViewActivityDetail)
    UIHelper.ScrollToTop(self.ScrollViewActivityDetail, 0)
    UIHelper.LayoutDoLayout(self.FlexLayoutDetail)
    UIHelper.LayoutDoLayout(self.FixedLayoutDetail)

    UIHelper.SetTouchDownHideTips(self.ScrollViewActivityDetail, false)    
end

return UIWidgetTraveList