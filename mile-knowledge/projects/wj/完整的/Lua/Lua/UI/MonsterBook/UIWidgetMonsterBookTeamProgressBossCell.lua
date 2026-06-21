local UIWidgetMonsterBookTeamProgressBossCell = class("UIWidgetMonsterBookTeamProgressBossCell")

function UIWidgetMonsterBookTeamProgressBossCell:OnEnter(tBossParam, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tBossParam = tBossParam
    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIWidgetMonsterBookTeamProgressBossCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookTeamProgressBossCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then self.fCallBack() end
    end)
end

function UIWidgetMonsterBookTeamProgressBossCell:RegEvent()

end

function UIWidgetMonsterBookTeamProgressBossCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookTeamProgressBossCell:UpdateInfo()
    local tBossParam = self.tBossParam
    local dwNpcID = tBossParam.dwNpcID
    local colorNum = self:GetPlayerNumBgColor()
    local szPath
    if not dwNpcID then
        local dwNpcIndex = tBossParam.dwNpcIndex
        local tBossNpcInfo = Table_GetDungeonBossModel(dwNpcIndex)
        dwNpcID = tBossNpcInfo.dwNpcID
    end
    if not szPath then
        local szAvatarPath, nAvatarFrame = Table_GetFBCDBossAvatar(dwNpcID)
        szAvatarPath = string.gsub(szAvatarPath, "ui/Image/UITga/", "Resource/DungeonBossHead/")
        szAvatarPath = string.gsub(szAvatarPath, ".UITex", "")
        szPath = string.format("%s/%02d.png", szAvatarPath, nAvatarFrame)
    end
    local szBossName = tBossParam.szBossName
    
    UIHelper.SetTexture(self.ImgHead, szPath)
    UIHelper.SetColor(self.ImgBgNum, colorNum)
    UIHelper.SetString(self.LabelNum, tostring(tBossParam.nHasNotKilledPlayerNum))
    UIHelper.SetString(self.LabelBossName, szBossName)
end

function UIWidgetMonsterBookTeamProgressBossCell:GetPlayerNumBgColor()
    local tBossParam = self.tBossParam
    local fRatio = tBossParam.nHasNotKilledPlayerNum / math.max(1, tBossParam.nTotalPlayers)
    if fRatio <= 0.201 then
        return cc.c3b(0xFF, 0x75, 0x75)  --- 红色
    elseif fRatio <= 0.601 then
        return cc.c3b(0xFF, 0xE2, 0x6E)  --- 黄色
    else
        return cc.c3b(0x95, 0xFF, 0x95)  --- 绿色
    end
end

return UIWidgetMonsterBookTeamProgressBossCell