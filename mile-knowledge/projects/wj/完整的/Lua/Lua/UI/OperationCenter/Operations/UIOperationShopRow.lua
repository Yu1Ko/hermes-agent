-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationShopRow
-- Date: 2026-04-20 15:06:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationShopRow = class("UIOperationShopRow")



function UIOperationShopRow:OnEnter(nNpcID, nShopID, dwPlayerRemoteDataID, tInfos, tCellCustomInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nNpcID = nNpcID
    self.nShopID = nShopID
    self.dwPlayerRemoteDataID = dwPlayerRemoteDataID
    self.tInfos = tInfos
    self.tCellCustomInfo = tCellCustomInfo
    self:UpdateInfo()
end

function UIOperationShopRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationShopRow:BindUIEvent()

end

function UIOperationShopRow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationShopRow:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationShopRow:UpdateInfo()
    self.tScriptList = self.tScriptList or {}
    for i = 1, 3 do
        local tInfo = self.tInfos[i]
        if tInfo then
            if self.tScriptList[i] then
                self.tScriptList[i]:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, tInfo, nil, nil, self.tCellCustomInfo)
                UIHelper.SetVisible(self.tScriptList[i]._rootNode, true)
            else
                self.tScriptList[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetStoreItem, self._rootNode, self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, tInfo, nil, nil, self.tCellCustomInfo)
            end

        else
            if self.tScriptList[i] then
                UIHelper.SetVisible(self.tScriptList[i]._rootNode, false)
            end
        end
    end
end


return UIOperationShopRow