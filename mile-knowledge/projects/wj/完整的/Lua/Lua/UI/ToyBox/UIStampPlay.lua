-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIStampPlay
-- Date: 2023-04-23 10:34:01
-- Desc: 特殊玩具玉铃颂春界面
-- ---------------------------------------------------------------------------------

local UIStampPlay = class("UIStampPlay")

function UIStampPlay:OnEnter(tStampInfo, nPage, nIndex)
    self.tStampInfo = tStampInfo
    if not nPage or nPage == 0 then
        nPage = 1
    end
    self.nPage = nPage - 1
    self.nIndex = nIndex
    self.bFirstEnter = true
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIStampPlay:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIStampPlay:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    for k, v in ipairs(self.TogList) do
        UIHelper.BindUIEvent(v, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.nPage = k - 1
                UIHelper.SetPageIndex(self.PageViewStamp, self.nPage)
                self:JudgeBtnChange()
                self:UpdateStampInfo()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnChangeOver01, EventType.OnClick, function ()
        self.nPage = self.nPage - 1
        UIHelper.SetPageIndex(self.PageViewStamp, self.nPage)
        UIHelper.SetToggleGroupSelected(self.TogGroupRewardItem,self.nPage)
        self:JudgeBtnChange()
        self:UpdateStampInfo()
    end)

    UIHelper.BindUIEvent(self.BtnChangeOver02, EventType.OnClick,function ()
        self.nPage = self.nPage + 1
        UIHelper.SetPageIndex(self.PageViewStamp, self.nPage)
        UIHelper.SetToggleGroupSelected(self.TogGroupRewardItem,self.nPage)
        self:JudgeBtnChange()
        self:UpdateStampInfo()
    end)

    UIHelper.BindUIEvent(self.PageViewStamp, EventType.OnTurningPageView, function ()
        Timer.AddFrame(self, 1, function ()
            local nPage = UIHelper.GetPageIndex(self.PageViewStamp)
            if self.bFirstEnter then
                nPage = self.nPage
                self.bFirstEnter = false
            end
              UIHelper.SetPageIndex(self.PageViewStamp, nPage)
              self.nPage = nPage
              UIHelper.SetToggleGroupSelected(self.TogGroupRewardItem, self.nPage)
              self:JudgeBtnChange()
              self:UpdateStampInfo()
        end)

    end)

end

function UIStampPlay:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIStampPlay:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIStampPlay:UpdateInfo()
    for index, value in ipairs(self.TogList) do
        UIHelper.ToggleGroupAddToggle(self.TogGroupRewardItem, value)
    end
    UIHelper.LayoutDoLayout(self.LayoutRewardItem)
    UIHelper.ScrollViewDoLayout(self.PageViewStamp)

    UIHelper.SetPageIndex(self.PageViewStamp, self.nPage)
    UIHelper.SetToggleGroupSelected(self.TogGroupRewardItem,self.nPage)
    self:JudgeBtnChange()
    self:UpdateStampInfo()

end

function UIStampPlay:JudgeBtnChange()
    UIHelper.SetVisible(self.BtnChangeOver01, self.nPage ~= 0)
    UIHelper.SetVisible(self.BtnChangeOver02, self.nPage ~= 3)
end

function UIStampPlay:UpdateStampInfo()
    local tbCurPageImgInfo = self.tStampInfo[self.nPage + 1]
    local nIndex = self.nPage + 1
    local pageItem = self.PageViewStamp:getItem(self.nPage)
    local tbPage = UIHelper.GetChildren(pageItem)
    local tbChildren = UIHelper.GetChildren(tbPage[1])
    if nIndex ~= 2 then
        for i, node in ipairs(tbChildren) do
            local imgStamp = UIHelper.GetChildByName(node, string.format("ImgStamp0%d", i))
            UIHelper.SetVisible(imgStamp, tbCurPageImgInfo[i])
        end
    else
        local tbWidget05 = UIHelper.GetChildByName(tbChildren[1], "WidgetStamp05")
        local tbImgList = UIHelper.GetChildren(tbWidget05)
        for i, node in ipairs(tbImgList) do
            UIHelper.SetVisible(node, tbCurPageImgInfo[i])
        end 
    end
end

return UIStampPlay