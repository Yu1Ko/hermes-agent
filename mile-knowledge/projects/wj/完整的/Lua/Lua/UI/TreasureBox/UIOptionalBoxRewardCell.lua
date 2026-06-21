-- ---------------------------------------------------------------------------------
-- 自选宝箱奖励cell
-- WidgetOptionalBoxRewardCell
-- WidgetOptionalBoxRewardCell2 外装
-- WidgetOptionalBoxRewardCell3 坐骑
-- ---------------------------------------------------------------------------------

local UIOptionalBoxRewardCell = class("UIOptionalBoxRewardCell")

local RewardCellType = {
    Pet = 1,
    Exterior = 2,
    Item = 3
}

function UIOptionalBoxRewardCell:_LuaBindList()
    self.ImgReward              = self.ImgReward --- 奖励图片
    self.ImgGet                 = self.ImgGet --- 是否已获得
    self.TogSelect              = self.TogSelect --- 详情按钮，点击出tip
    self.LabelRewardName        = self.LabelRewardName --- 奖励name
end

function UIOptionalBoxRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bBtn = {}
end

function UIOptionalBoxRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOptionalBoxRewardCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnRewardTip, true)
    UIHelper.BindUIEvent(self.BtnRewardTip, EventType.OnClick, function ()
        self:UpdateTip()
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (tog, bSelected)
        if self.fnCallBack then
            self.fnCallBack(bSelected)
        end
    end)
end

function UIOptionalBoxRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOptionalBoxRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIOptionalBoxRewardCell:UpdateInfo(tInfo)
    local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szItem)
    self.dwType = dwType
    self.dwIndex = dwIndex

    if tInfo.szVKImagePath and tInfo.szVKImagePath ~= "" then
        UIHelper.SetTexture(self.ImgReward, tInfo.szVKImagePath)
    else
        local BoxItem = ItemData.GetItemInfo(dwType, dwIndex)
        UIHelper.SetItemIconByItemInfo(self.ImgReward, BoxItem)
    end

    UIHelper.SetString(self.LabelRewardName, UIHelper.GBKToUTF8(tInfo.szName))

    UIHelper.SetVisible(self.ImgGet, tInfo.bHave and not tInfo.bNotCollect)
end

function UIOptionalBoxRewardCell:UpdateTip()
    if self.dwType and  self.dwIndex then
        local _, tipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.BtnRewardTip)
        local tbBtnInfo = {}
        if OutFitPreviewData.CanPreview(self.dwType, self.dwIndex) then
            local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(self.dwType, self.dwIndex)
            if not table.is_empty(tbPreviewBtn) then
                table.insert(tbBtnInfo, tbPreviewBtn[1])
            end
        end
        tipsView:SetFunctionButtons(tbBtnInfo)

        tipsView:OnInitWithTabID(self.dwType, self.dwIndex)
    end
end

function UIOptionalBoxRewardCell:SetCallBack(fnCallBack)
    self.fnCallBack = fnCallBack
end

return UIOptionalBoxRewardCell