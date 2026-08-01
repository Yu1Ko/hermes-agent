-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventureTryBook
-- Date: 2023-07-27 10:53:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local ONE_PAGE_TRYBOOK = 5

local UIAdventureTryBook = class("UIAdventureTryBook")

function UIAdventureTryBook:OnEnter(fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fnAction = fnAction

    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIAdventureTryBook:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventureTryBook:BindUIEvent()
    UIHelper.TableView_addCellAtIndexCallback(self.TableViewRight, function(tableView, nIndex, script, node, cell)
        local tInfo = self.tAdvList[nIndex]
        if tInfo and script then
            if not self.dwSelectedAdv then
                self.dwSelectedAdv = tInfo
                Event.Dispatch(EventType.OnSelectAdventureTryBookCell, tInfo, self.bZhenQi)
            end
            local bSelected = self.dwSelectedAdv.dwID == tInfo.dwID
            if self.bZhenQi then
                script:UpdateZhenQi(tInfo, bSelected)
            else
                script:UpdateXiYou(tInfo, bSelected)
            end

        end
    end)
end

function UIAdventureTryBook:RegEvent()
    Event.Reg(self, EventType.OnSelectAdventureTryBookCell, function(tInfo)
        self.dwSelectedAdv = tInfo
    end)
end

function UIAdventureTryBook:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventureTryBook:UpdateZhenQiTryBook(tAdvList)
    self.tAdvList = tAdvList
    self.bZhenQi = true
    self.dwSelectedAdv = nil

    UIHelper.TableView_init(self.TableViewRight, #tAdvList, PREFAB_ID.WidgetNotesCell)
    UIHelper.TableView_reloadData(self.TableViewRight)

    UIHelper.SetVisible(self.WidgetEmpty, #tAdvList == 0)
    UIHelper.SetVisible(self.LabelTitle2, true)

    if #tAdvList == 0 then
        Event.Dispatch(EventType.OnSelectAdventureTryBookCell, nil, false)
    end
end

function UIAdventureTryBook:UpdateXiYouTryBook(tAdvList)
    self.tAdvList = tAdvList
    self.bZhenQi = false
    self.dwSelectedAdv = nil

    UIHelper.TableView_init(self.TableViewRight, #tAdvList, PREFAB_ID.WidgetNotesCell)
    UIHelper.TableView_reloadData(self.TableViewRight)

    UIHelper.SetVisible(self.WidgetEmpty, #tAdvList == 0)
    UIHelper.SetVisible(self.LabelTitle2, false)

    if #tAdvList == 0 then
        Event.Dispatch(EventType.OnSelectAdventureTryBookCell, nil, false)
    end
end

return UIAdventureTryBook