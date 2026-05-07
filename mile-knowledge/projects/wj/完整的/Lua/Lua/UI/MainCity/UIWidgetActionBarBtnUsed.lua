-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetActionBarBtnUsed
-- Date: 2023-12-06 17:10:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetActionBarBtnUsed = class("UIWidgetActionBarBtnUsed")

function UIWidgetActionBarBtnUsed:OnEnter(nIndex, tbMarkInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.tbMarkInfo = tbMarkInfo
    self:UpdateInfo()
end

function UIWidgetActionBarBtnUsed:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetActionBarBtnUsed:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTeamMark, EventType.OnClick, function()
        self:OnBtnClick()
    end)
end

function UIWidgetActionBarBtnUsed:RegEvent()
    --竞技场相关
    Event.Reg(self, "PLAYER_ENTER_SCENE", function()
        if ArenaData.IsInArena() then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnArenaPlayerUpdate, function()
        if ArenaData.IsInArena() then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "TARGET_MINI_AVATAR_MISC", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "OnTargetChanged", function(nTargetType, nSelectID)
        self:UpdateSelect(nSelectID, nTargetType)
    end)

    Event.Reg(self, EventType.OnActionBarBtnClick, function(nIndex, bIsDown)
        if nIndex == self.nIndex and not bIsDown then
            self:OnBtnClick()
        end
    end)
end

function UIWidgetActionBarBtnUsed:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetActionBarBtnUsed:UpdateInfo()
    local tbMarkInfo = self.tbMarkInfo
    if tbMarkInfo.dwMarkID then
        UIHelper.SetSpriteFrame(self.ImgTeamMark, TeamData.TargetMarkIcon[tbMarkInfo.dwMarkID])
    end

    UIHelper.SetVisible(self.ImgTeamMark, tbMarkInfo.dwMarkID ~= nil)

    if tbMarkInfo.nTargetType == TARGET.PLAYER then
        local pTarget = GetPlayer(tbMarkInfo.dwCharacterID)
        if not pTarget then
            pTarget = tbMarkInfo.npc
        end
        -- UIHelper.RoleChange_UpdateAvatar(self.ImgHead, pTarget.dwMiniAvatarID, nil, nil, pTarget.nRoleType, pTarget.dwForceID, true)

        local nKungFuID
        if pTarget then
            nKungFuID = pTarget.GetActualKungfuMountID()
        end

        if not nKungFuID then
            if ArenaData.IsInArena() then
                local tbData = ArenaData.GetBattlePlayerData(true)
                for i, tbInfo in ipairs(tbData) do
                    if tbInfo.dwID == tbMarkInfo.dwCharacterID then
                        nKungFuID = tbInfo.dwMountKungfuID
                        break
                    end
                end
            end
        end
        UIHelper.ClearTexture(self.ImgHead)
        if not nKungFuID then
            if pTarget then
                UIHelper.SetTexture(self.ImgHead, DefaultAvatar[pTarget.dwForceID])
            end
        else
            UIHelper.SetSpriteFrame(self.ImgHead, PlayerKungfuImg[nKungFuID])
        end

    else
        local szHeadImg = NpcData.GetNpcHeadImage(tbMarkInfo.dwCharacterID)
        UIHelper.SetSpriteFrame(self.ImgHead, szHeadImg)
    end

    local szName = tbMarkInfo.szName
    if szName ~= "" then
        szName = UIHelper.GetUtf8SubString(szName, 1, 3)--名字只取前三个字
        UIHelper.SetString(self.labelName, szName)
    end
    UIHelper.SetVisible(self.ImgName, szName ~= "")

    UIHelper.SetVisible(self.ImgDead1, tbMarkInfo.bDeath)

    local nSelectID, nTargetType = TargetMgr.GetSelect()
    self:UpdateSelect(nSelectID, nTargetType)
end

function UIWidgetActionBarBtnUsed:OnBtnClick()
    local tbMarkInfo = self.tbMarkInfo
    TargetMgr.doSelectTarget(tbMarkInfo.dwCharacterID, tbMarkInfo.nTargetType)
end

function UIWidgetActionBarBtnUsed:UpdateSelect(nSelectID, nTargetType)
    local tbMarkInfo = self.tbMarkInfo
    local bSelect = tbMarkInfo.dwCharacterID == nSelectID and tbMarkInfo.nTargetType == nTargetType
    UIHelper.SetVisible(self.ImgSelect, bSelect)
end

return UIWidgetActionBarBtnUsed