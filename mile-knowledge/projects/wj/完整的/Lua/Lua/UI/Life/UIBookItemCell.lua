-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItemCell
-- Date: 2022-12-09 15:26:45
-- Desc: ?
-- WidgetBookNameItem
-- ---------------------------------------------------------------------------------

local UIBookItemCell = class("UIBookItemCell")

function UIBookItemCell:OnEnter(nSegmentID, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSegmentID = nSegmentID
    self.fCallBack = fCallBack

    UIHelper.SetSwallowTouches(self.TogHelp, true)
end

function UIBookItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookItemCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogBookSkip, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnBookItemCellSelect, self.TogBookSkip, self.nSegmentID)
    end) 

    UIHelper.BindUIEvent(self.TogHelp, EventType.OnClick, function ()
        self.fCallBack(self.TogHelp)
    end)

    UIHelper.BindUIEvent(self.ToggleMultiSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.fMultiSelectCallBack(bSelected)
    end)
end

function UIBookItemCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBookItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIBookItemCell:SetTitleName(szName, color)
    -- 按照规范替换字符
    szName = CraftData.BookNameOptimize(szName)

    -- 书名超过9个字拆成两段
    local nCharNum = GetStringCharCount(szName)
    local bNeedSplit = nCharNum > 9
    UIHelper.SetVisible(self.LabelBookNameTitleNoRead, not bNeedSplit)
    UIHelper.SetVisible(self.LabelBookNameTitleRead, not bNeedSplit)
    UIHelper.SetVisible(self.LabelTitleNoRead1, bNeedSplit)
    UIHelper.SetVisible(self.LabelTitleNoRead2, bNeedSplit)
    UIHelper.SetVisible(self.LabelTitleRead1, bNeedSplit)
    UIHelper.SetVisible(self.LabelTitleRead2, bNeedSplit)

    if not bNeedSplit then        
        UIHelper.SetString(self.LabelBookNameTitleNoRead, szName)
        UIHelper.SetString(self.LabelBookNameTitleRead, szName)
    else        
        local szName1 = UTF8SubString(szName, 1, 9)
        local szName2 = UTF8SubString(szName, 10, #szName - 9)
        UIHelper.SetString(self.LabelTitleNoRead1, szName1)
        UIHelper.SetString(self.LabelTitleNoRead2, szName2)
        UIHelper.SetString(self.LabelTitleRead1, szName1)
        UIHelper.SetString(self.LabelTitleRead2, szName2)
    end

    if color then
        --UIHelper.SetColor(self.LabelBookNameTitleNoRead, color)
        --UIHelper.SetColor(self.LabelBookNameTitleRead, color)
    end   
end

function UIBookItemCell:SetBookReadState(bRead)
    self.bRead = bRead
    UIHelper.SetVisible(self.WidgetRead, bRead)
    UIHelper.SetVisible(self.WidgetNoRead, not bRead)    
end

function UIBookItemCell:SetImgOwn()
    UIHelper.SetVisible(self.ImgOwn, true)
end

function UIBookItemCell:SetImgOtherOwn()
    UIHelper.SetVisible(self.ImgOtherOwn, true)
end

function UIBookItemCell:SetMultiSelectCallBack(fMultiSelectCallBack)
    self.fMultiSelectCallBack = fMultiSelectCallBack
end

function UIBookItemCell:SetMultiSelectEnable(bEnable)
    UIHelper.SetTouchEnabled(self.TogBookSkip, not bEnable)
    UIHelper.SetVisible(self.ToggleMultiSelect, bEnable)
    UIHelper.SetVisible(self.TogHelp, not bEnable)
end

function UIBookItemCell:UpdateInfo()
    
end


return UIBookItemCell