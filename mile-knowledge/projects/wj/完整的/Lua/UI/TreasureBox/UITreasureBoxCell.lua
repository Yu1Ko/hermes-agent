-- ---------------------------------------------------------------------------------
-- 宝箱cell
-- WidgetTreasureBox
-- ---------------------------------------------------------------------------------

local UITreasureBoxCell = class("UITreasureBoxCell")

function UITreasureBoxCell:_LuaBindList()
    self.ToggleTreasureSeries   = self.ToggleTreasureSeries --- toggle
    self.LabelNomal             = self.LabelNomal --- 宝箱名字
    self.LabelSelected          = self.LabelSelected --- 宝箱名字
    self.LabelBagHave           = self.LabelBagHave --- 拥有：xxx
    self.ImgTreasureBox         = self.ImgTreasureBox --- 图片
end

function UITreasureBoxCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITreasureBoxCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBoxCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleTreasureSeries, EventType.OnSelectChanged, function(_,bSelected)
        if bSelected and self.fnCallBack then
            self.fnCallBack()
        end
	end)
end

function UITreasureBoxCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBoxCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBoxCell:UpdateInfo(tInfo)
    local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem, false)
    local BoxItem = ItemData.GetItemInfo(dwType, dwIndex)
    local szName = UIHelper.GBKToUTF8(tInfo.szItemName)
    local bCanSplit = string.find(szName, "·") and UIHelper.GetUtf8Len(szName) > 7

    local LabelNomal = self.LabelNomal
    local LabelSelected = self.LabelSelected
    local LabelBagHave = self.LabelBagHave

    if bCanSplit then
        szName = string.gsub(szName, "·", "·\n", 1)
        LabelNomal = self.LabelNomal2
        LabelSelected = self.LabelSelected2
        LabelBagHave = self.LabelBagHave2

        UIHelper.SetVisible(self.LabelNomal, false)
        UIHelper.SetVisible(self.LabelNomal2, true)
        UIHelper.SetVisible(self.LabelSelected, false)
        UIHelper.SetVisible(self.LabelSelected2, true)
        UIHelper.SetVisible(self.LabelBagHave, false)
        UIHelper.SetVisible(self.LabelBagHave2, true)
    end

    UIHelper.SetString(LabelNomal, szName)
    UIHelper.SetString(LabelSelected, szName)

    local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)
    UIHelper.SetString(LabelBagHave, "拥有" .. nBagNum)
    UIHelper.SetItemIconByItemInfo(self.ImgTreasureBox, BoxItem)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UITreasureBoxCell:SetCallBack(func)
    self.fnCallBack = func
end

function UITreasureBoxCell:UpdateNum(nFixNum)
    UIHelper.SetString(self.LabelBagHave, "拥有" .. nFixNum)
end

return UITreasureBoxCell