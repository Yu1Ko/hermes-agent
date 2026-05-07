-- ---------------------------------------------------------------------------------
-- 奇遇奖励cell
-- WidgetQiYuBoxRewardCell
-- ---------------------------------------------------------------------------------

local UIQiYuBoxRewardCell = class("UIQiYuBoxRewardCell")

function UIQiYuBoxRewardCell:_LuaBindList()
    self.TogQiYuSelect          = self.TogQiYuSelect --- tog
    self.LabelRewardName        = self.LabelRewardName --- 奇遇名字
    self.BtnRewardTip           = self.BtnRewardTip --- 详情按钮跳转至奇遇
    self.ImgState               = self.ImgState --- 奇遇状态
    self.ImgReward              = self.ImgReward --- 奇遇图片
end

function UIQiYuBoxRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIQiYuBoxRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQiYuBoxRewardCell:BindUIEvent()

end

function UIQiYuBoxRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    UIHelper.BindUIEvent(self.TogQiYuSelect, EventType.OnSelectChanged, function(_,bSelected)
        if bSelected and self.fnCallBack then
            self.fnCallBack()
        end
	end)


    UIHelper.BindUIEvent(self.BtnRewardTip, EventType.OnClick, function()
        if self.bItem then
            TipsHelper.DeleteAllHoverTips()
            local _, uiItemTipScript = TipsHelper.ShowItemTips(self.BtnRewardTip, self.dwType, self.dwIndex)
            uiItemTipScript:SetBtnState({})
        else
            local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelQiYu)
            if not scriptView then
                UIMgr.Open(VIEW_ID.PanelQiYu, nil, self.nLuckyID)
                UIMgr.Close(VIEW_ID.PanelQiYuTreasureBox)
            else
                scriptView:OnEnter(nil, self.nLuckyID)
                UIMgr.Close(VIEW_ID.PanelQiYuTreasureBox)
            end
        end
	end)

end

function UIQiYuBoxRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local tImg = {
    [1] = "UIAtlas2_QiYu_QiYu_Tag_YiChuFa", --已触发
    [2] = "UIAtlas2_QiYu_QiYu_Tag3", --机缘未到
    [3] = "UIAtlas2_QiYu_QiYu_Tag2", --等待探索
    [4] = "UIAtlas2_QiYu_QiYu_Tag4", --已收集
}

function UIQiYuBoxRewardCell:UpdateInfo(tInfo)
    UIHelper.SetString(self.LabelRewardName, tInfo.szName)
    if tInfo.bItem then
        self.bItem = true
        self.dwType = tInfo.dwType
        self.dwIndex = tInfo.dwIndex
        UIHelper.SetVisible(self.ImgState, false)
        -- UIHelper.SetVisible(self.ImgTip, false)

        if tInfo.szImgFile and tInfo.szImgFile ~= "" then
            UIHelper.SetTexture(self.ImgReward, tInfo.szImgFile)
        else
            local BoxItem = ItemData.GetItemInfo(tInfo.dwType, tInfo.dwIndex)
            UIHelper.SetItemIconByItemInfo(self.ImgReward, BoxItem)
        end
    else
        self.bItem = false
        self.nLuckyID = tInfo.nLuckyID
        UIHelper.SetTexture(self.ImgReward, tInfo.szImgFile)

        UIHelper.SetVisible(self.ImgState, false)

        local bCollect = false
        if tInfo.dwType and tInfo.dwIndex then
            local nAllBag = g_pClientPlayer.GetItemAmountInAllPackages(tInfo.dwType, tInfo.dwIndex)
            if nAllBag and nAllBag ~= 0 then
               bCollect = true
            end
        end

        if tInfo.nChanceState == ADVENTURE_CHANCE_STATE.NO_CHANCE then
            UIHelper.SetVisible(self.ImgState, true)
            UIHelper.SetSpriteFrame(self.ImgState, tImg[2])
        elseif tInfo.bTrigger then
            UIHelper.SetVisible(self.ImgState, true)
            UIHelper.SetSpriteFrame(self.ImgState, tImg[1])
        elseif bCollect then
            UIHelper.SetVisible(self.ImgState, true)
            UIHelper.SetSpriteFrame(self.ImgState, tImg[4])
        elseif tInfo.nChanceState == ADVENTURE_CHANCE_STATE.EXPLORED then
            UIHelper.SetVisible(self.ImgState, true)
            UIHelper.SetSpriteFrame(self.ImgState, tImg[3])
        end

        if tInfo.nChanceState == ADVENTURE_CHANCE_STATE.EXPLORED or tInfo.nChanceState == ADVENTURE_CHANCE_STATE.NO_CHANCE then
            UIHelper.SetVisible(self.ImgTip, true)
        else
            UIHelper.SetVisible(self.ImgTip, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LabelRewardName)
end

function UIQiYuBoxRewardCell:SetCallBack(func)
    self.fnCallBack = func
end


return UIQiYuBoxRewardCell