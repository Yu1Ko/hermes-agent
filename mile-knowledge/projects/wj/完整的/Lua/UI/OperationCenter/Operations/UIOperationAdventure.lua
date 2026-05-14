-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationAdventure
-- Date: 2026-04-13 10:11:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationAdventure = class("UIOperationAdventure")

local tAdventureList   = {159, 160, 161}

function UIOperationAdventure:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    self.scriptLayoutTaskList = self.tComponentContext.tScriptLayoutTop[3]
    self:UpdateInfo()
end

function UIOperationAdventure:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationAdventure:BindUIEvent()

end

function UIOperationAdventure:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationAdventure:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationAdventure:UpdateInfo()
    AdventureData.InitLuckyTable(true)

    local parent = self.scriptLayoutTaskList.WidgetLayOutTaskList
    UIHelper.RemoveAllChildren(parent)

    for _, dwID in ipairs(tAdventureList) do
        local tInfo = Table_GetAdventureByID(dwID)
        local tTryBookList = Table_GetAdventureTryBook(dwID)
        local tTryBookInfo = tTryBookList[1]
        if tInfo and tTryBookInfo then
            local tPet   = Table_GetFellowPet(tTryBookInfo.dwPetID)
            UIHelper.AddPrefab(PREFAB_ID.WidgetNewInfoAdventure, parent, tInfo, tPet)
        end
    end
    UIHelper.LayoutDoLayout(parent)
end


return UIOperationAdventure