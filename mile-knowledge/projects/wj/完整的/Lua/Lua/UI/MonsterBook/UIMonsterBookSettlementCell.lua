local UIMonsterBookSettlementCell = class("UIMonsterBookSettlementCell")

function UIMonsterBookSettlementCell:OnEnter(tPlayerInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo(tPlayerInfo, nIndex)
end

function UIMonsterBookSettlementCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookSettlementCell:BindUIEvent()

end

function UIMonsterBookSettlementCell:RegEvent()

end

function UIMonsterBookSettlementCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonsterBookSettlementCell:UpdateInfo(tPlayerInfo, nIndex)
    local dwPlayerID, pPlayer = tPlayerInfo.dwPlayerID, nil
    if dwPlayerID then
        pPlayer = GetPlayer(dwPlayerID)
    end
    local bExist = pPlayer ~= nil
    local szTitle = g_tStrings.MONSTER_BOOK_MVP_TYPE[nIndex]
    if bExist then
        local szName = UIHelper.GBKToUTF8(tPlayerInfo.szName)
        --local szImagePath = PlayerForceID2SchoolImg[tPlayerInfo.dwForceID]
        
        UIHelper.SetString(self.LabelPlayerName, szName)
        UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead108, dwPlayerID)
    else
        UIHelper.SetString(self.LabelPlayerName, "暂无")
    end
    UIHelper.SetString(self.LabelTitle, szTitle)
    UIHelper.SetVisible(self.ImgEmpty, not bExist)

    if pPlayer then
        UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[pPlayer.dwForceID])
    end
    UIHelper.SetVisible(self.ImgSchool, bExist)
end

return UIMonsterBookSettlementCell