-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitNavigationFilter
-- Date: 2023-03-24 17:15:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UITeamRecruitNavigationFilter
local UITeamRecruitNavigationFilter = class("UITeamRecruitNavigationFilter")

function UITeamRecruitNavigationFilter:OnInit(nNavigationPrefabID, nFilterPrefabID, fnCheckedCallback, fnPlayShow, fnPlayHide, nNavigationLongPrefabID)
    self.nNavigationPrefabID = nNavigationPrefabID
    self.nNavigationLongPrefabID = nNavigationLongPrefabID
    self.nFilterPrefabID =  nFilterPrefabID
    self.fnCheckedCallback = fnCheckedCallback
    self.fnPlayShow = fnPlayShow
    self.fnPlayHide = fnPlayHide

    if self.fnPlayShow then
        self.fnPlayShow()
    end

    self.tbCheckedMenu = nil
    self.tbNaviCells = {}
    self.tbFilterCells = {}

    UIHelper.RemoveAllChildren(self.ScrollViewBreadNaviScreen)
    UIHelper.RemoveAllChildren(self.ScrollViewFilterList)

    self:UpdateInfo()
end

function UITeamRecruitNavigationFilter:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITeamRecruitNavigationFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.fnPlayHide then
        self.fnPlayHide()
    end
end

function UITeamRecruitNavigationFilter:BindUIEvent()
end

function UITeamRecruitNavigationFilter:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitNavigationFilter:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitNavigationFilter:UpdateInfo()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.fnCloseCallback then
            self.fnCloseCallback()
        end
    end)
end

function UITeamRecruitNavigationFilter:SetChecked(tbMenu, bLocate)
    if #tbMenu > 0 then
        local nTotal = #self.tbNaviCells
        local bChecked = false
        for i = 1, nTotal do
            if self.tbNaviCells[i].tbMenu == tbMenu then
                bChecked = true
            end
            if not bChecked then
                self.tbNaviCells[i]:SetChecked(true)
            else
                UIHelper.RemoveFromParent(self.tbNaviCells[i]._rootNode, true)
                self.tbNaviCells[i] = nil
            end
        end
        local fnAction = function (tbSubMenu)
            self:SetChecked(tbSubMenu)
        end
        ---@type UITeamRecruitBreadNaviItem
        local naviCell
        if self.nNavigationLongPrefabID and UIHelper.GetUtf8Len(tbMenu.szOption) > 5 then
            naviCell = UIHelper.AddPrefab(self.nNavigationLongPrefabID, self.ScrollViewBreadNaviScreen)
        else
            naviCell = UIHelper.AddPrefab(self.nNavigationPrefabID, self.ScrollViewBreadNaviScreen)
        end
        naviCell:OnEnter(tbMenu, #self.tbNaviCells == 0, fnAction)
        table.insert(self.tbNaviCells, naviCell)
        UIHelper.ScrollViewDoLayout(self.ScrollViewBreadNaviScreen)
        UIHelper.ScrollToLeft(self.ScrollViewBreadNaviScreen, 0)
        UIHelper.RemoveAllChildren(self.ScrollViewFilterList)
        self.tbFilterCells = {}
        for _, tbSubMenu in ipairs(tbMenu) do
            ---@type UITeamRecruitFilterItem
            local filterCell = UIHelper.AddPrefab(self.nFilterPrefabID, self.ScrollViewFilterList)
            filterCell:OnEnter(tbSubMenu, fnAction)
            table.insert(self.tbFilterCells, filterCell)
        end
        UIHelper.ScrollViewDoLayout(self.ScrollViewFilterList)
        UIHelper.ScrollToTop(self.ScrollViewFilterList, 0)
        self.tbCheckedMenu = nil
    else
        for _, filterCell in ipairs(self.tbFilterCells) do
            local bChecked = tbMenu == filterCell.tbMenu
            filterCell:SetChecked(bChecked)
            -- 自动定位
            if bChecked and bLocate then
                Timer.DelTimer(self, self.nLocateTimerID)
                self.nLocateTimerID = Timer.AddFrame(self, 1, function ()
                    if filterCell and filterCell.bInit then
                        CoinShopPreview.LocatePreviewItem(self.ScrollViewFilterList, filterCell._rootNode)
                    end
                end)
            end
        end
        self.tbCheckedMenu = tbMenu
    end
    if self.fnCheckedCallback then
        self.fnCheckedCallback(self.tbCheckedMenu, bLocate)
    end
end

function UITeamRecruitNavigationFilter:SetCloseCallback(fnCloseCallback)
    self.fnCloseCallback = fnCloseCallback
end

return UITeamRecruitNavigationFilter