-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationGongZhanTaskCell
-- Date: 2026-03-25
-- Desc: WidgetGongZhanTaskCell 参考UIActivityCellView
-- ---------------------------------------------------------------------------------

local UIOperationGongZhanTaskCell = class("UIOperationGongZhanTaskCell")

local Class2IconPath = {
    [1] = "UIAtlas2_Collection_CollectionNewIcon_TogBg2.png",
    [2] = "UIAtlas2_Collection_CollectionNewIcon_TogBg4.png",
    [3] = "UIAtlas2_Collection_CollectionNewIcon_TogBg3.png",
    [4] = "UIAtlas2_Collection_CollectionNewIcon_TogBg5.png",
}
function UIOperationGongZhanTaskCell:OnEnter(tbActiveInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tbActiveInfo then
        self.tbActiveInfo = tbActiveInfo
        self.fnOnClick = tbActiveInfo.fnOnClick
        self:UpdateInfo()
    end
end

function UIOperationGongZhanTaskCell:OnExit()
    self.bInit = false
end

function UIOperationGongZhanTaskCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTaskList100, EventType.OnClick, function()
        if self.fnOnClick then
            self.fnOnClick(self.tbActiveInfo and self.tbActiveInfo.tInfo)
        end
    end)
end

function UIOperationGongZhanTaskCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationGongZhanTaskCell:UpdateInfo()
    local bFinished, nCurCount, nTolCount = CollectionData.GetFinishState(self.tbActiveInfo.tInfo)

    -- 活动名称
    local szName = UIHelper.GBKToUTF8(self.tbActiveInfo.szName or "")
    if nTolCount > 1 then
        szName = szName .. string.format("（%d/%d）", nCurCount, nTolCount)
    end
    UIHelper.SetString(self.LabelContent1, szName)

    -- 时间描述
    local szTime = self.tbActiveInfo.szTime
    if szTime and szTime ~= "" then
        UIHelper.SetString(self.LabelContent2, UIHelper.GBKToUTF8(szTime))
    else
        UIHelper.SetVisible(self.LabelContent2, false)
    end

    local szIconPath = Class2IconPath[self.tbActiveInfo.tInfo.nClass1]
    if self.tbActiveInfo.tInfo.nClass1 <= 1 then
        szIconPath = Class2IconPath[1]
    end
    UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath)

    UIHelper.RemoveAllChildren(self.LayOutRewardItem)
    -- if self.tbActiveInfo.tInfo.szReward then
    --     local tRewards = {}
    --     local tItemList = SplitString(self.tbActiveInfo.tInfo.szReward, ";")
    --     for _, v in pairs(tItemList) do
    --         local tt = SplitString(v, "_")
    --         table.insert(tRewards, {dwType = tonumber(tt[1]) or tt[1], dwIndex = tonumber(tt[2]), nCount = tonumber(tt[3])})
    --     end

    --     for _, tReward in ipairs(tRewards) do
    --         local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayOutRewardItem)
    --         if tReward.dwType ~= "COIN" then
    --             cell:OnInitWithTabID(tReward.dwType, tReward.dwIndex, tReward.nCount)
    --         else
    --             local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayOutRewardItem)
    --             local tbLine = Table_GetCalenderActivityAwardIconByID(tReward.dwIndex) or {}
    --             local szName = CurrencyNameToType[tbLine.szName]
    --             cell:OnInitCurrency(szName, tReward.nCount)
    --         end
    --     end
    --     UIHelper.LayoutDoLayout(self.LayOutRewardItem)
    -- end


    local bOpen = true
    if self.tbActiveInfo.tInfo.nClass1 == CLASS_MODE.DEFAULT
        and not CollectionData.IsDailyDungeon(self.tbActiveInfo.tInfo.dwMapID) then
        bOpen = false
    end

    if bOpen then
        if self.tbActiveInfo.tInfo.szActivity then
            bOpen = CollectionData.GetGuideIsOpen(self.tbActiveInfo.tInfo)
        elseif self.tbActiveInfo.tInfo.bOpen ~= nil then
            bOpen = self.tbActiveInfo.tInfo.bOpen
        end
    end

    UIHelper.SetVisible(self.ImgTaskListBgFinish, bOpen and bFinished)
    UIHelper.SetVisible(self.ImgTaskArrow, not bOpen or not bFinished)
    UIHelper.SetVisible(self.ImgMask, bOpen and not bFinished)

    if bOpen and bFinished then
        UIHelper.SetButtonState(self.BtnTaskList100, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnTaskList100, BTN_STATE.Normal)
    end
end

return UIOperationGongZhanTaskCell