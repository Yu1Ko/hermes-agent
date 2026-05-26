-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: UIArenaQiXuePage
-- Date: 2025-7-3 14:48:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIArenaQiXuePage
local UIArenaQiXuePage = class("UIArenaQiXuePage")
local MAX_PLAYER_COUNT =  5

function UIArenaQiXuePage:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tCount = {
        [0] = 0,
        [1] = 0,
    }

    self.tScriptCell = {}
    self.tPlayerList = tInfo
    self:UpdateInfo()
end

function UIArenaQiXuePage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIArenaQiXuePage:BindUIEvent()

end

function UIArenaQiXuePage:RegEvent()

end

function UIArenaQiXuePage:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIArenaQiXuePage:UpdateInfo()
    self:UpdatePlayerListPage(0, self.tbScriptPlayerL)
    self:UpdatePlayerListPage(1, self.tbScriptPlayerR)
    self:UpdatePageName(true, false)
end

function UIArenaQiXuePage:UpdateSinglePlayer(dwID, tInfo)
    local nSide  = tInfo.nIndex
    local tList  = self.tbScriptPlayerL
    local nCount = self.tCount[nSide]
    if nSide == 1 then
        tList  = self.tbScriptPlayerR
    end
    if not tInfo then
        return
    end
    if self.tPlayerList[dwID] then
        self.tPlayerList[dwID] = tInfo
    else
        self.tPlayerList[dwID] = tInfo
        if #tList < MAX_PLAYER_COUNT then
            local hCell = tList[nCount]
            self:UpdatePlayerCell(hCell, tInfo)
            nCount = nCount + 1
            self.tCount[nSide] = nCount
        end      
    end
end

function UIArenaQiXuePage:UpdatePlayerListPage(nIndex, tList)
    local nCount = 0 

    for dwID, tInfo in pairs(self.tPlayerList) do
        if tInfo and tInfo.nIndex == nIndex then
            nCount = nCount + 1
            local hCell = tList[nCount]
            self:UpdatePlayerCell(hCell, tInfo)
        end
    end

    self.tCount[nIndex] = nCount
    for i = nCount + 1, MAX_PLAYER_COUNT do
        local hCell= tList[i]
        UIHelper.SetVisible(hCell, false)
    end
end

function UIArenaQiXuePage:UpdatePlayerCell(hCell, tInfo)
    if tInfo then
        local scriptCell = UIHelper.GetBindScript(hCell)
        hCell.dwID = tInfo.dwID
        UIHelper.SetVisible(hCell, true)
        scriptCell:OnEnter(tInfo)   
        table.insert(self.tScriptCell, scriptCell)
    end
end

function UIArenaQiXuePage:OnUpdatePage(bQiXue, bSkill)
    for _, scriptCell in pairs(self.tScriptCell) do
        scriptCell:OnUpdatePage(bQiXue, bSkill)   
    end  
    self:UpdatePageName(bQiXue, bSkill)
end

function UIArenaQiXuePage:UpdatePageName(bQiXue, bSkill)
    if bQiXue then
        UIHelper.SetString(self.LabelTitleBlue2, g_tStrings.STR_QIXUE_PAGE)
        UIHelper.SetString(self.LabelTitleRed2, g_tStrings.STR_QIXUE_PAGE)
    else
        UIHelper.SetString(self.LabelTitleBlue2, g_tStrings.STR_SKILL_PAGE)
        UIHelper.SetString(self.LabelTitleRed2, g_tStrings.STR_SKILL_PAGE)
    end
    
end

return UIArenaQiXuePage