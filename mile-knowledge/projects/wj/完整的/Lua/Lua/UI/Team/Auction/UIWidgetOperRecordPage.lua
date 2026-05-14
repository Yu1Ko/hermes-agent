-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOperRecordPage
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOperRecordPage = class("UIWidgetOperRecordPage")

function UIWidgetOperRecordPage:OnEnter(tData)
    if not tData then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
    Timer.AddCycle(self, 1, function ()
        self:OnFrameBreathe()
    end)
end

function UIWidgetOperRecordPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetOperRecordPage:BindUIEvent() 
    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function ()
        AuctionData.tCustomData.tDistributeRecords = {}
        AuctionData.bOperRecordDirty = true
    end)   
    UIHelper.TableView_addCellAtIndexCallback(self.TableViewRecord, function(tableView, nIndex, script, node, cell)
        local nSize = #AuctionData.tCustomData.tDistributeRecords
        local tRecord = AuctionData.tCustomData.tDistributeRecords[nSize - nIndex + 1]
        if not tRecord or not script then
            return
        end
        script:OnEnter(tRecord)
    end)
end

function UIWidgetOperRecordPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOperRecordPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOperRecordPage:UpdateInfo()
    UIHelper.TableView_init(self.TableViewRecord, #AuctionData.tCustomData.tDistributeRecords, PREFAB_ID.WidgetOperRecordItem)
    UIHelper.TableView_reloadData(self.TableViewRecord)
    UIHelper.SetVisible(self.WidgetOperRecordMainTitle, #AuctionData.tCustomData.tDistributeRecords > 0)
    UIHelper.SetVisible(self.WidgetAnchorEmpty, #AuctionData.tCustomData.tDistributeRecords == 0)
end

function UIWidgetOperRecordPage:OnFrameBreathe()
    if not AuctionData.bOperRecordDirty then
        return
    end
    AuctionData.bOperRecordDirty = false
    UIHelper.TableView_init(self.TableViewRecord, #AuctionData.tCustomData.tDistributeRecords, PREFAB_ID.WidgetOperRecordItem)
    UIHelper.TableView_reloadData(self.TableViewRecord)
    UIHelper.SetVisible(self.WidgetOperRecordMainTitle, #AuctionData.tCustomData.tDistributeRecords > 0)
    UIHelper.SetVisible(self.WidgetAnchorEmpty, #AuctionData.tCustomData.tDistributeRecords == 0)
end

return UIWidgetOperRecordPage