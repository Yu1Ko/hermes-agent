-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCampCell
-- Date: 2025-03-18 15:29:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetCampCell = class("UIWidgetCampCell")

function UIWidgetCampCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    if tbInfo then
        self:UpdateInfo()
    end
end

function UIWidgetCampCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCampCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (_ ,bSelect)
            --框住区域
        Event.Dispatch(EventType.OnSelectCampCell, bSelect and self.tbInfo.nPQID or nil)
    end)
end

function UIWidgetCampCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCampCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCampCell:UpdateInfo()
    local tbInfo = self.tbInfo
    UIHelper.SetString(self.LabelHaoQiAll, tbInfo.nGoodTotalCount)
    UIHelper.SetString(self.LabelHaoQiDie, tbInfo.nGoodTotalCount - tbInfo.nGoodLiveCount)
    UIHelper.SetString(self.LabelHaoQiActivity, tbInfo.nGoodLiveCount)
    UIHelper.SetString(self.LabelERenAll, tbInfo.nEvilTotalCount)
    UIHelper.SetString(self.LabelERenDie, tbInfo.nEvilTotalCount - tbInfo.nEvilLiveCount)
    UIHelper.SetString(self.LabelERenActivity, tbInfo.nEvilLiveCount)

    --第一个名字
    local tbAreaInfo = Table_GetHeatMapAreaInfoByPQ(tbInfo.nPQID)
    UIHelper.SetString(self.LabelBOSS1, UIHelper.GBKToUTF8(tbAreaInfo.szName))
    UIHelper.SetString(self.LabelBOSS3, UIHelper.GBKToUTF8(tbAreaInfo.szName))

    --第一个头像
    local szImage = HEATMAP_DETAILLIST_HEADIMG[tbAreaInfo.nType]
    UIHelper.SetSpriteFrame(self.ImgIcon1_Normal, szImage)
    UIHelper.SetSpriteFrame(self.ImgIcon1_Select, szImage)

    --名字之间的线
    UIHelper.SetVisible(self.WidgetLine, false)
    UIHelper.SetVisible(self.WidgetLine_Select, false)

    --第二个头像
    UIHelper.SetVisible(self.ImgIcon2_Normal, false)
    UIHelper.SetVisible(self.ImgIcon2_Select, false)

    --第二个名字
    UIHelper.SetVisible(self.LabelBOSS2, false)
    UIHelper.SetVisible(self.LabelBOSS4, false)

    UIHelper.LayoutDoLayout(self.LayoutTtile_Select)
    UIHelper.LayoutDoLayout(self.LayoutTtile_Select1)



    UIHelper.SetTouchEnabled(self.TogSelect, false)

end


return UIWidgetCampCell