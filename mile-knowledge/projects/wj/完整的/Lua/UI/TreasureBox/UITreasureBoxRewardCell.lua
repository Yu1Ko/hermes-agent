-- ---------------------------------------------------------------------------------
-- 宝箱奖励cell
-- WidgetTreasureBoxRewardCell
-- ---------------------------------------------------------------------------------

local UITreasureBoxRewardCell = class("UITreasureBoxRewardCell")

function UITreasureBoxRewardCell:_LuaBindList()
    self.ImgReward              = self.ImgReward --- 奖励图片
    self.ImgGet                 = self.ImgGet --- 是否已获得
    self.BtnRewardTip           = self.BtnRewardTip --- 详情按钮，点击出tip
    self.LabelRewardName        = self.LabelRewardName --- 奖励name
    self.LayoutItemName         = self.LayoutItemName --- LabelRewardName上层
end

function UITreasureBoxRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITreasureBoxRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBoxRewardCell:BindUIEvent()
    UIHelper.SetTouchEnabled(self.LayoutItemName, true)
    UIHelper.BindUIEvent(self.LayoutItemName, EventType.OnClick, function()
        self:ShowItemTips()
    end)

    UIHelper.BindUIEvent(self.BtnRewardTip, EventType.OnClick, function ()
        self:ShowItemTips()
    end)
end

function UITreasureBoxRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBoxRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBoxRewardCell:UpdateInfo(tInfo)
    local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szItem)
    self.dwType = dwType
    self.dwIndex = dwIndex
    local BoxItem = ItemData.GetItemInfo(dwType, dwIndex)

    UIHelper.RemoveAllChildren(self.WidgetHeadFrame)
    UIHelper.SetVisible(self.WidgetHeadFrame, false)
    UIHelper.SetVisible(self.ImgReward, false)
    if tInfo.nAvatarID and tInfo.nAvatarID ~= 0 then
        UIHelper.SetVisible(self.WidgetHeadFrame, true)
        local avatarCell = UIHelper.AddPrefab(PREFAB_ID.WidgetHeadListItem, self.WidgetHeadFrame)
        assert(avatarCell)
        avatarCell:UpdateBoxReward(tInfo.nAvatarID)
    elseif tInfo.szVKImagePath and tInfo.szVKImagePath ~= "" then
        UIHelper.SetVisible(self.ImgReward, true)
        UIHelper.SetTexture(self.ImgReward, tInfo.szVKImagePath)
    else
        UIHelper.SetVisible(self.ImgReward, true)
        UIHelper.SetItemIconByItemInfo(self.ImgReward, BoxItem)
    end

    -- self.bShowBtn = true
    -- local nSub = BoxItem.nSub
    -- local nGenre = BoxItem.nGenre
    -- if nGenre ~= ITEM_GENRE.EQUIPMENT or (nGenre == ITEM_GENRE.EQUIPMENT and nSub == EQUIPMENT_SUB.MINI_AVATAR) then
    --     self.bShowBtn = false
    -- end

    UIHelper.SetString(self.LabelRewardName, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.LayoutDoLayout(self.LayoutItemName)

    local bHave = TreasureBoxData.IsHaveItem(tInfo)
    UIHelper.SetVisible(self.ImgGet, bHave)
    if not bHave then
        self.fnBeAllHaveFalse()
    end
end


function UITreasureBoxRewardCell:SetCallBack(func)
    self.fnCallBack = func
end

function UITreasureBoxRewardCell:SetBeAllHaveFalse(func)
    self.fnBeAllHaveFalse = func
end

function UITreasureBoxRewardCell:ShowItemTips()
    if self.dwType and  self.dwIndex then
        local _, tipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.BtnRewardTip)
        -- if self.bShowBtn then
        --     local tbBtn = OutFitPreviewData.SetPreviewBtn(self.dwType, self.dwIndex)
        --     if tbBtn and tbBtn[1] and tbBtn[1].OnClick then
        --         self.fnClick = tbBtn[1].OnClick
        --         local tInfo = {{ szName = "试穿", OnClick = tbBtn[1].OnClick}}
        --         tipsView:SetFunctionButtons(tInfo)
        --     else
        --         tipsView:SetFunctionButtons({})
        --     end
        -- end
        local tbButton = {}
        if self.dwType and self.dwIndex and OutFitPreviewData.CanPreview(self.dwType, self.dwIndex) then
            local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(self.dwType, self.dwIndex)
            if not table.is_empty(tbPreviewBtn) then
                table.insert(tbButton, tbPreviewBtn[1])
            end
        end
        tipsView:SetFunctionButtons(tbButton)
        tipsView:OnInitWithTabID(self.dwType, self.dwIndex)
    end
end
return UITreasureBoxRewardCell