-- ---------------------------------------------------------------------------------
-- 奇遇box cell
-- WidgetQiYuBox
-- ---------------------------------------------------------------------------------

local UIQiYuBoxCell = class("UIQiYuBoxCell")

function UIQiYuBoxCell:_LuaBindList()
    self.ToggleTreasureSeries   = self.ToggleTreasureSeries --- toggle
    self.LabelNomal             = self.LabelNomal --- 宝箱名字
    self.LabelBagHave           = self.LabelBagHave --- 拥有：xxx
    self.ImgTreasureBox         = self.ImgTreasureBox --- 图片
end

function UIQiYuBoxCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIQiYuBoxCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQiYuBoxCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleTreasureSeries, EventType.OnSelectChanged, function(_,bSelected)
        if bSelected and self.fnCallBack then
            self.fnCallBack()
        end
	end)
end

function UIQiYuBoxCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQiYuBoxCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQiYuBoxCell:UpdateInfo(tInfo)
    local BoxItem = ItemData.GetItemInfo(tInfo.dwType, tInfo.dwIndex)
    UIHelper.SetItemIconByItemInfo(self.ImgTreasureBox, BoxItem)

    UIHelper.SetString(self.LabelNomal, tInfo.szItemName)

    local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)

    UIHelper.SetString(self.LabelBagHave, "拥有" .. nBagNum)
end

function UIQiYuBoxCell:SetCallBack(func)
    self.fnCallBack = func
end

function UIQiYuBoxCell:UpdateNum(nFixNum)
    UIHelper.SetString(self.LabelBagHave, "拥有" .. nFixNum)
end

return UIQiYuBoxCell