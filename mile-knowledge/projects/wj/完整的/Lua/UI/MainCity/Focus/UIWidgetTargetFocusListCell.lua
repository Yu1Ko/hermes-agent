-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInvitationMessagePop
-- Date: 2023-03-24 09:24:58
-- Desc: PanelInvitationMessagePop
-- ---------------------------------------------------------------------------------

local mfloor, mceil, mmin, mmax, mpi, matan2, msqrt = math.floor, math.ceil, math.min, math.max, math.pi, math.atan2, math.sqrt
local sformat = string.format
local _L = JX.LoadLangPack
local DOUBLE_CLICK_INTERVAL = 400

local szDefaultIconPath = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (1).png"

local UIWidgetTargetFocusListCell = class("UIWidgetTargetFocusListCell")

function UIWidgetTargetFocusListCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self.szLastSpriteIcon = nil
    UIHelper.SetSwallowTouches(self.BtnPlayer, true)
    UIHelper.SetSwallowTouches(self.BtnDirection, false)
end

function UIWidgetTargetFocusListCell:OnExit()

end

function UIWidgetTargetFocusListCell:BindUIEvent()
    UIHelper.SetClickInterval(self.TogTargetFocusListCell, 0)
    UIHelper.BindUIEvent(self.TogTargetFocusListCell, EventType.OnClick, function()
        JX_TargetList.bdoSelect = true -- 当前是否发起选择
        if IsPlayer(self.dwID) then
            TargetMgr.doSelectTarget(self.dwID, TARGET.PLAYER)
        else
            TargetMgr.doSelectTarget(self.dwID, TARGET.NPC)
        end

        if self.tInfo and self.tInfo.bIsFocus then
            local nCurTime = GetTickCount()
            if self.nLastKeyTime and nCurTime - self.nLastKeyTime < DOUBLE_CLICK_INTERVAL then
                _JX_TargetList.SetJihuoTar(self.dwID)
            end
            self.nLastKeyTime = nCurTime
        end
    end)

    UIHelper.BindUIEvent(self.BtnPlayer, EventType.OnClick, function()
        self:ShowPop()
    end)

    UIHelper.BindUIEvent(self.BtnDirection, EventType.OnClick, function()
        self:ShowPop()
    end)
end

function UIWidgetTargetFocusListCell:RegEvent()

end

function UIWidgetTargetFocusListCell:UpdateInfo(tInfo, player)
    player = player or GetClientPlayer()

    if not tInfo or not tInfo.hObject.dwID or not player then
        return
    end
    local hObject = tInfo.hObject
    local playerID = player.dwID
    self.tInfo = tInfo
    self.dwID = hObject.dwID
    self.szName = JX.GetObjectName(hObject)
    
    local szName = self.szName
    local dwForceID = self.tInfo.bIsDoodad and -1 or hObject.dwForceID
    local szImgSchoolPath = PlayerForceID2SchoolImg2[dwForceID] or szDefaultIconPath

    local src = self.dwID
    local dest = playerID
    if not self.tInfo.bIsDoodad and IsPlayer(self.dwID) then
        src = playerID
        dest = self.dwID

        local dwSkillID = JX.GetKungfuMountID(hObject)
        if dwSkillID and dwSkillID ~= 0 then
            szImgSchoolPath = PlayerKungfuImg[dwSkillID] or szDefaultIconPath
        else
            szImgSchoolPath = UIHelper.GetSchoolIcon(hObject.dwSchoolID)
        end
    end

    UIHelper.SetVisible(self.ImgFocusPermanentIcon, tInfo.bIsFocus)
    UIHelper.SetVisible(self.PlayerBloodHighLight, tInfo.bIsFocus)

    UIHelper.SetVisible(self.BtnDirection, self.tInfo.bIsDoodad)
    UIHelper.SetVisible(self.BtnPlayer, not self.tInfo.bIsDoodad)

    if self.tInfo.bIsDoodad then
        local nRelRad = matan2(hObject.nY - player.nY, hObject.nX - player.nX)
        local nMeRad = player.nFaceDirection / 128 * mpi
        local nFinalRad = nMeRad - nRelRad
        local nTansferedFinalRad = nFinalRad / mpi * 180
        UIHelper.SetRotation(self.ImgDirection, nTansferedFinalRad)
    else
        local nMyMark = _JX_TargetList.tPartyMark[self.dwID] or 0
        local szIconPath = TeamData.TargetMarkIcon[nMyMark]
        if szIconPath then
            if not self.szLastSpriteIcon or self.szLastSpriteIcon ~= szIconPath then
                UIHelper.SetSpriteFrame(self.ImgPlayerTag, szIconPath)
                self.szLastSpriteIcon = szIconPath
            end
            UIHelper.SetVisible(self.ImgPlayerTag, true)
        else
            UIHelper.SetVisible(self.ImgPlayerTag, false)
        end
    end


    UIHelper.SetString(self.LabelPlayerName, UIHelper.LimitUtf8Len(szName, 6))
    UIHelper.SetSpriteFrame(self.ImgPlayerSchool, szImgSchoolPath)

    local szColor = TARGET_FOCUS_COLOR_NEUTRAL_C3B
    if self.dwID == player.dwID then
        szColor = TARGET_FOCUS_COLOR_SELF_C3B
    elseif IsAlly(src, dest) or IsParty(src, dest) or IsFakeAlly(self.dwID) then
        szColor = TARGET_FOCUS_COLOR_ALLY_C3B
    elseif IsEnemy(src, dest) then
        szColor = TARGET_FOCUS_COLOR_ENEMY_C3B
    end

    UIHelper.SetProgressBarPercent(self.PlayerBloodHighLight, JX_TargetList.bPerImg and tInfo._perLife or 100)
    UIHelper.SetProgressBarPercent(self.SliderPlayerBlood, JX_TargetList.bPerImg and tInfo._perLife or 100)
    UIHelper.SetColor(self.SliderPlayerBlood, szColor)
    UIHelper.SetColor(self.PlayerBloodHighLight, szColor)

    local szNum = ""
    if JX_TargetList.nSortType < 2 then
        szNum = tInfo._perLife .. "%"
    else
        if tInfo.nDis >= 100 then
            szNum = sformat("%d", tInfo.nDis)
        else
            szNum = sformat("%.1f", tInfo.nDis)
        end
    end
    UIHelper.SetString(self.LabelNum, szNum)

    local bDarkNormal = not tInfo.bIsFocus and JX_TargetList.bFootDis and tInfo.nDis > JX_TargetList.nFootDis
    local bDarkFocus = tInfo.bIsFocus and JX_TargetList.bFarFocusDark and tInfo.nDis > JX_TargetList.nFarFocusDis
    if bDarkNormal or bDarkFocus then
        UIHelper.SetOpacity(self._rootNode, 120)
    else
        UIHelper.SetOpacity(self._rootNode, 255)
    end

    local _, dwID = player.GetTarget()
    UIHelper.SetVisible(self.ImgSelect, dwID == hObject.dwID)
end

function UIWidgetTargetFocusListCell:ShowPop()
    local me = GetClientPlayer()
    local tInfo = self.tInfo
    local dwID = self.dwID

    if dwID and not tInfo.bIsDoodad and me.dwID ~= dwID and IsPlayer(dwID) then
        local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPlayerPop, self._rootNode, TipsLayoutDir.AUTO, dwID, nil, nil, false)
        if UIHelper.GetWorldPositionX(script._rootNode) < UIHelper.GetWorldPositionX(self._rootNode) then
            tips:SetOffset(100, 0)
            tips:Update()
        end
        script:AddFocusMenus({})
    else
        local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetTipMoreOper, self._rootNode, TipsLayoutDir.AUTO)
        tips:SetOffset(0, -30)
        tips:Update()
        script:OnEnter(JX_TargetList.GenerateMenuConfig(dwID, self.szName, tInfo.bIsDoodad, false))
    end
end

return UIWidgetTargetFocusListCell