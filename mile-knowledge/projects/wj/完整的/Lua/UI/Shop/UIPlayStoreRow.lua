local UIPlayStoreRow = class("UIPlayStoreRow")


function UIPlayStoreRow:OnEnter(tShopCellInfoList, toggleGroup, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tShopCellInfoList, toggleGroup, fCallBack)
end

function UIPlayStoreRow:OnExit()
    self.bInit = false
end

function UIPlayStoreRow:BindUIEvent()
    
end

function UIPlayStoreRow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlayStoreRow:UpdateInfo(tShopCellInfoList, toggleGroup, fCallBack)
    local goodsScripts = {}
    for i,cell in ipairs(self.WidgetPlayStoreCells) do        
        local scriptCell
        if i <= #tShopCellInfoList then
            local tShopCell = tShopCellInfoList[i]
            scriptCell = UIHelper.GetBindScript(cell)
            if scriptCell then
                UIHelper.SetVisible(cell, true)
                UIHelper.ToggleGroupAddToggle(toggleGroup, scriptCell.ToggleSelect)
                scriptCell:OnEnter(tShopCell.nNpcID, tShopCell.nShopID, tShopCell.dwPlayerRemoteDataID, tShopCell.tbGoods, tShopCell.bNeedGray)
                table.insert(goodsScripts, scriptCell)
            end
        end
        UIHelper.SetVisible(cell, scriptCell ~= nil)
    end
    fCallBack(goodsScripts)
end

return UIPlayStoreRow