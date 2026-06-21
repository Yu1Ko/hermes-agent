-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPopDropListView
-- Date: 2022-11-28 14:50:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPopDropListView = class("UIPopDropListView")

function UIPopDropListView:OnEnter(szTitle, szTipContent, tbItems, nDefaultSelectKey, confirmCallback)
    self.szTitle = szTitle
    self.szTipContent = szTipContent
    self.tbItems = tbItems -- {{nKey = 1, szText = "Text" }}
    self.nDefaultSelectKey = nDefaultSelectKey
    self.nSelectKey = nDefaultSelectKey
    self.confirmCallback = confirmCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCount = #self.tbItems

    self:UpdateInfo()
end

function UIPopDropListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPopDropListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        if self.confirmCallback and self.nDefaultSelectKey ~= self.nSelectKey then
            self.confirmCallback(self.nSelectKey)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogRecommend, EventType.OnSelectChanged, function (_, bSelected)
        if self.nCount <= 4 then
            UIHelper.SetVisible(self.LayoutUnfold1, bSelected)
        else
            UIHelper.SetVisible(self.ImgUnfoldBg, bSelected)
        end
    end)
end

function UIPopDropListView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPopDropListView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPopDropListView:UpdateInfo()
    if self.szTitle then
        UIHelper.SetString(self.LabelTitle, self.szTitle)
    end
    if self.szTipContent then
        UIHelper.SetString(self.LaberRemarks, self.szTipContent)
    end
    UIHelper.RemoveAllChildren(self.LayoutUnfold1)
    UIHelper.RemoveAllChildren(self.ScrollViewDropList)

    local parent
    if self.nCount <= 4 then
        parent = self.LayoutUnfold1
    else
        parent = self.ScrollViewDropList
    end

    for _, tbItem in ipairs(self.tbItems) do
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSelectTog530X86, parent)
        scriptItem:OnEnter(tbItem.nKey, tbItem.szText, function (nKey, szText)
            self.nSelectKey = nKey
            UIHelper.SetSelected(self.TogRecommend, false)
            UIHelper.SetString(self.LabelRecommend, szText)
        end, tbItem.nKey == self.nSelectKey)

        if tbItem.nKey == self.nSelectKey then
            UIHelper.SetString(self.LabelRecommend, tbItem.szText)
        end

        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, scriptItem.ToggleSelect)
    end

    if self.nCount <= 4 then
        UIHelper.LayoutDoLayout(self.LayoutUnfold1)
    else
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDropList)
    end
end


return UIPopDropListView