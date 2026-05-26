--PanelCollectDetailed

local UIPanelCollectDetailed = class("UIPanelCollectDetailed")

local Index2Name = {
    [1] = {total = "挂件",
            detail = {"面部", "眼饰", "左肩饰", "右肩饰", "左手饰", "右手饰", "背部", "披风", "腰部", "佩囊", "头饰", "挂宠", }},
    [2] = {total = "外观",
            detail = {"成衣", "外装收集", "武器收集"}},
    [3] = {total = "易容",
            detail = {"脸型", "发型", "体型"}},
    [4] = {total = "坐骑",
            detail = {"坐骑", "奇趣坐骑", "马具"}},
    [5] = {total = "宠物",
            detail = {"奇遇宠物", "稀有羁绊", "珍贵羁绊", "经典羁绊"}},
    [6] = {total = "小玩意",
            detail = {"玩具", "特效", "小头像", "侠士名贴", "表情动作", "头顶表情"}},
    [7] = {total ="家具",
            detail = {"建筑", "家具", "景观", "笔刷", "私宅皮肤"}}
}

function UIPanelCollectDetailed:OnEnter(tInfo, nSelectedID)
    self.tInfo = tInfo
    self.nSelectedID = nSelectedID
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not self.nSelectedID then
        self.nSelectedID = 1
    else
        UIHelper.SetSelected(self.tbTogGroup[1], false)
    end
    
    if self.nSelectedID then
        UIHelper.SetSelected(self.tbTogGroup[self.nSelectedID], true)
    end
end

function UIPanelCollectDetailed:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCollectDetailed:Init()
    
end

function UIPanelCollectDetailed:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelCollectDetailed)
    end)

    for index, tog in ipairs(self.tbTogGroup) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (btn, bSelected)
            if not bSelected then return end
            UIHelper.SetString(self.LabelTitle, Index2Name[index].total)
            self.nSelectedID = index
            self:UpdateInfo()
        end)
    end
end

function UIPanelCollectDetailed:RegEvent()
    --
end

function UIPanelCollectDetailed:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelCollectDetailed:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetAnchorCollectDetailedPendant)
    self.scriptPage = UIHelper.AddPrefab(PREFAB_ID.WidgetCollectDetailedPendant, self.WidgetAnchorCollectDetailedPendant,
        Index2Name[self.nSelectedID], self.tInfo[self.nSelectedID])
end

return UIPanelCollectDetailed