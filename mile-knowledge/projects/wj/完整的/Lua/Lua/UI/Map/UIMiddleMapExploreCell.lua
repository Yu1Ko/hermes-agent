-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiddleMapExploreCell
-- Date: 2025-09-18 17:13:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiddleMapExploreCell = class("UIMiddleMapExploreCell")

function UIMiddleMapExploreCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nType        = tInfo.nType
    self.nFinishCount = tInfo.nFinishCount
    self.nTotalCount  = tInfo.nTotalCount
    self:UpdateInfo()
end

function UIMiddleMapExploreCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiddleMapExploreCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnContent, EventType.OnClick, function()
        Event.Dispatch("MAP_EXPLORE_NOTIFY", self.nType)
    end)
end

function UIMiddleMapExploreCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiddleMapExploreCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiddleMapExploreCell:UpdateInfo()
    local tTypeInfo = MapHelper.GetMapExploreTypeInfo(self.nType)
    if not tTypeInfo then
        return
    end
    local szNum   = string.format("%d/%d", self.nFinishCount, self.nTotalCount)
    local szName  = UIHelper.GBKToUTF8(tTypeInfo.szName)
    local bFinish = self.nFinishCount == self.nTotalCount
    if bFinish then
        UIHelper.SetString(self.LabelUpNum, szNum)
        UIHelper.SetString(self.LabelUpTitle, szName)
        UIHelper.SetVisible(self.WidgetDone, true)
    else
        UIHelper.SetString(self.LabelNormalNum, szNum)
        UIHelper.SetString(self.LabelNormalTitle, szName)
        UIHelper.SetVisible(self.WidgetDone, false)
    end
    -- UIHelper.SetVisible(self.ImgDone, bFinish)
    UIHelper.SetVisible(self.LabelUpNum, false)
    UIHelper.SetVisible(self.LabelUpTitle, bFinish)
    UIHelper.SetVisible(self.LabelNormalNum, not bFinish)
    UIHelper.SetVisible(self.LabelNormalTitle, not bFinish)
    UIHelper.SetSpriteFrame(self.ImgExplore, tTypeInfo.szMBFrame)
    UIHelper.SetSwallowTouches(self.BtnContent, false)
end


return UIMiddleMapExploreCell