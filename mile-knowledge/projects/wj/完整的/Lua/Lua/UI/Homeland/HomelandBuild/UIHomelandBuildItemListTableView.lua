-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildItemListTableView
-- Date: 2024-08-28 16:55:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildItemListTableView = class("UIHomelandBuildItemListTableView")

function UIHomelandBuildItemListTableView:Init(tItemList, szTitle)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tItemList = tItemList or {}
    UIHelper.TableView_init(self.TableView, #self.tItemList, PREFAB_ID.WidgetPlacedItemCell)
    UIHelper.TableView_reloadData(self.TableView)
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIHomelandBuildItemListTableView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandBuildItemListTableView:BindUIEvent()
    UIHelper.TableView_addCellAtIndexCallback(self.TableView, function(tableView, nIndex, script, node, cell)
        if not self.tItemList or table.is_empty(self.tItemList) then
            return
        end

        local tItem = self.tItemList[nIndex]
        if tItem and script then
            script:OnEnter(tItem.tArgs)
            script:AddToggleGroup(self.TogGroupItem)
            UIHelper.BindUIEvent(script.ToggleSelect, EventType.OnClick, function ()
                if tItem.tArgs.dwModelGroupID then
                    local tInfo = HLBOp_Group.GetGroupInfo(tItem.tArgs.dwModelGroupID)
                    if tInfo then
                        HLBOp_Select.SelectOneGroup(tItem.tArgs.dwModelGroupID)
                        -- HLBView_Main.ChangeFocusToHLB()
                    end
                else
                    HLBOp_Select.SetItemSelect(tItem.tArgs.dwObjID)
                    HLBOp_Other.FocusObject(tItem.tArgs.dwObjID)
                end
            end)
        end
    end)
end

function UIHomelandBuildItemListTableView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildItemListTableView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandBuildItemListTableView:UpdateInfo()
    
end


return UIHomelandBuildItemListTableView