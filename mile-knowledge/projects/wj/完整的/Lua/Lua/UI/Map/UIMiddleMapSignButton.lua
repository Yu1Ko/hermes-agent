local UIMiddleMapSignButton = class("UIMiddleMapSignButton")
local HP_COLOR = cc.c3b(33, 183, 213)

function UIMiddleMapSignButton:RegisterEvent()
    Event.Reg(self, "ON_MIDDLE_MAP_SIGN_TOGGLE", function(obj, bSelected)
        if self.bIsMapPvp then
            return
        end
        if bSelected and obj ~= self then
            if UIHelper.GetSelected(self.TogSign) then
                UIHelper.SetSelected(self.TogSign, false, false)
            end
        end
    end)

    Event.Reg(self, "ON_START_MOVE_BOARD_NODE", function(script)
        if self.bIsMapPvp then
            return
        end
        UIHelper.SetTouchEnabled(self.TogSign, false)
    end)

    Event.Reg(self, "ON_END_MOVE_BOARD_NODE", function(script)
        if self.bIsMapPvp then
            return
        end
        UIHelper.SetTouchEnabled(self.TogSign, true)
    end)
    UIHelper.BindUIEvent(self.TogSign, EventType.OnSelectChanged, function(_, bSelected)
        self.bSelected = bSelected
        if self.fnSelected then
            self.fnSelected(self.bSelected)
        end
        Event.Dispatch('ON_MIDDLE_MAP_SIGN_TOGGLE', self, bSelected)
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_SCALE_CHANGE", function()
        if self.bIsMapPvp then
            return
        end
        if not self.nLogicX or not self.nLogicY then
            return
        end

        if UIHelper.GetSelected(self.TogSign) then
            self:SetSelected(false, true)
        end
        Event.Dispatch("ON_MIDDLE_UPDATE_SIGN_BUTTON_POS", self, self.nLogicX, self.nLogicY)
    end)
end

function UIMiddleMapSignButton:OnEnter(nMapID)
    self.nMapID = nMapID
    self.WidgetAniSteer:setVisible(false)
    self:RegisterEvent()
end

function UIMiddleMapSignButton:OnExit()
end

function UIMiddleMapSignButton:SetPosition(x, y, nLogicX, nLogicY)
    self.nX = x
    self.nY = y
    self.nLogicX = nLogicX
    self.nLogicY = nLogicY
    if safe_check(self.TogSign) then
        local nScale = UIHelper.GetScale(self._rootNode)
        local offsetX, offsetY = self.TogSign:getPosition()
        self._rootNode:setPosition(x - offsetX * nScale, y - offsetY * nScale)
    end
end

function UIMiddleMapSignButton:GetPosition()
    local nX, nY = UIHelper.ConvertToWorldSpace(self._rootNode:getParent(), self.nX, self.nY)
    return nX, nY
end

function UIMiddleMapSignButton:SetIsMapPvp(bIsMapPvp)
    self.bIsMapPvp = bIsMapPvp
end

function UIMiddleMapSignButton:SetHighlight(bHighlight)
    self.WidgetAniSteer:setVisible(bHighlight)

    if bHighlight then
        self:LoadSFX()
    end
end

function UIMiddleMapSignButton:ShowExploreNotify(bShow)
    self.WidgetAniSteer:setVisible(bShow)

    if bShow then
        self:LoadSFX()
    end
end

function UIMiddleMapSignButton:LoadSFX()
    if self.bLoadedSFX then
        return
    end

    if self.Eff_BiaoJi then
        UIHelper.SetSFXPath(self.Eff_BiaoJi, UIHelper.UTF8ToGBK("data\\source\\other\\HD特效\\UI_M\\Pss\\Map\\UI_NPC标记.pss"))
        UIHelper.PlaySFX(self.Eff_BiaoJi)
    end

    self.bLoadedSFX = true
end

function UIMiddleMapSignButton:SetVisible(bVisible)
    self._rootNode:setVisible(bVisible)
end

function UIMiddleMapSignButton:SetRange(W, H)
    self.nMaxW = W
    self.nMaxH = H
end

function UIMiddleMapSignButton:GetNodeRotation()

end

function UIMiddleMapSignButton:SetFlag(tbInfo)
    self.tbInfo = tbInfo
    self.tbCommand = MapMgr.GetMarkInfoByTypeID(tbInfo.nType)
    self.tPoint = {nX = tbInfo.nX, nY = tbInfo.nY, nZ = Scene_GetFloor(tbInfo.nX, tbInfo.nY)}
    self.szFrame = UIHelper.GBKToUTF8(self.tbCommand.szMobileImage)
    self.szType = "BoardFlag"

    UIHelper.SetScale(self.ImgNormalicon, 1.5, 1.5)
    UIHelper.SetSpriteFrameWithFrameSize(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
    UIHelper.SetTouchEnabled(self.TogSign, MapMgr.IsPlayerCanDraw())
end

function UIMiddleMapSignButton:SetGather(nX, nY)
    self.tPoint = {nX = nX, nY = nY, nZ = Scene_GetFloor(nX, nY)}
    self.szFrame = "UIAtlas2_Map_MapIcon_img_icon_team2.png"
    self.szType = "BoardGather"

    UIHelper.SetScale(self.ImgNormalicon, 1.5, 1.5)
    UIHelper.SetSpriteFrameWithFrameSize(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
    UIHelper.SetTouchEnabled(self.TogSign, MapMgr.IsPlayerCanDraw())
end


function UIMiddleMapSignButton:SetNpc(tbInfo, tPoint, szFrame, szBgFrame, nCatalogue)

    local bInscription = tbInfo.id and tbInfo.id == 51 and tbInfo.nDoodadType and tbInfo.nDoodadType == 1--是否是碑铭
    self.tbInfo = tbInfo
    self.tPoint = tPoint
    self.szFrame = szFrame
    self.nCatalogue = nCatalogue
    self.szName = GBKToUTF8(Table_GetNpcTemplateName(self.tbInfo.nNpcID))
    self.szType =  bInscription and "Inscription" or "NPC"
    self.bNotTurnMainMap = true

    UIHelper.SetSpriteFrame(self.ImgNormalicon, szFrame)
    UIHelper.SetSpriteFrame(self.ImgNormaliconBg, szBgFrame)

    if bInscription then
        local bRead = ItemData.IsBookRead(tbInfo.nDoodadID)
        UIHelper.SetNodeGray(self.TogSign, bRead, true)
        self.bButtonGray = bRead
    end
end

function UIMiddleMapSignButton:SetBossInfo(tbInfo, tbCatalogue)
    self.tbInfo = tbInfo
    self.tPoint = {tbInfo.nX, tbInfo.nY, tbInfo.nZ}
    self.szFrame = IMG_BOSS_TRACE_ICON
    self.szName = tostring(tbInfo.nOrder) .. "-" .. UIHelper.GBKToUTF8(tbInfo.szName)
    self.szType = "BossInfo"
    self.bBoss = true

    UIHelper.SetVisible(self.ImgNormalicon, false)
    -- UIHelper.SetVisible(self.ImgNormaliconBg, false)
    UIHelper.SetVisible(self.ImgTransport_Boss, true)
    UIHelper.SetSpriteFrame(self.ImgNormaliconBg, tbCatalogue.szBgFrame)
    UIHelper.SetSpriteFrame(self.ImgTransport_Boss, tbCatalogue.szFrame)
    UIHelper.SetString(self.LabelTransport_Boss, tbInfo.nOrder)
end

function UIMiddleMapSignButton:SetSearchNpc(tbInfo)
    self.tbInfo = tbInfo
    self.tPoint = {tonumber(tbInfo.nX), tonumber(tbInfo.nY), tonumber(tbInfo.nZ)}
    self.szFrame = "UIAtlas2_Map_MapIcon_img_npc.png"
    self.szBgFrame = "UIAtlas2_Public_PublicIcon_PublicIcon1_MapIconBg1.png"--临时用一下
    -- self.nCatalogue = nCatalogue
    self.szName = UIHelper.GBKToUTF8(tbInfo.szName)
    self.szType = "SearchNpc"

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetSpriteFrame(self.ImgNormaliconBg, self.szBgFrame)
end

function UIMiddleMapSignButton:SetWanted(tbInfo, tbImgInfo)
    self.szFrame = tbImgInfo.ICON
    self.szType = "Wanted"
    self.szName = UIHelper.GBKToUTF8(tbInfo.szName)
    self.tbPoint = {tonumber(tbInfo.nX), tonumber(tbInfo.nY), tonumber(tbInfo.nZ)}

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetSpriteFrame(self.ImgNormaliconBg, tbImgInfo.BG)
end

function UIMiddleMapSignButton:SetTransfer(nMapID, tbInfo, tbIllegal)
    self.tbInfo = tbInfo
    self.szFrame = TRANSPORT_FRAME.ICON[tbInfo.nType or 0]
    self.szName =  self.tbInfo.szName
    self.szType = "Transfer"
    self.bTransfer = true

    self.ImgTransport:setVisible(true)
    if tbIllegal.Level or tbIllegal.Visit then
        UIHelper.SetNodeGray(self.ImgTransport, true)
        self.bIllegal = true
    end

    UIHelper.SetSpriteFrameWithFrameSize(self.ImgTransport, self.szFrame)
    UIHelper.SetVisible(self.ImgNormalicon, false)
end

function UIMiddleMapSignButton:SetTraffic(nMapID, tbInfo, tbIllegal)
    self.tbInfo = tbInfo
    self.szFrame = TRANSPORT_FRAME.ICON[tbInfo.nType or 0]
    self.szName =  self.tbInfo.szName
    self.szType = "Traffic"
    self.bTransfer = true

    self.ImgTransport:setVisible(true)
    if tbIllegal.Level or tbIllegal.Visit then
        UIHelper.SetNodeGray(self.ImgTransport, true)
        self.bIllegal = true
    end
    UIHelper.SetSpriteFrame(self.ImgTransport, self.szFrame)
    UIHelper.SetContentSize(self.ImgTransport, 80, 80)
    UIHelper.SetVisible(self.ImgNormalicon, false)
end

function UIMiddleMapSignButton:SetQuest(tbInfo, tPoint, szFrame, szBgFrame)
    local nQuestID, szType = unpack(tbInfo)
    self.tbInfo = tbInfo
    self.tPoint = tPoint
    self.nQuestID = nQuestID
    self.szFrame = szFrame
    self.szType = "Quest"
    self.bQuest = true

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetSpriteFrame(self.ImgNormaliconBg, szBgFrame)
end

function UIMiddleMapSignButton:SetMyQuest(nQuestID, tbPoints, nIndex, bFinished)
    self.nQuestID = nQuestID
    self.tPoint = tbPoints
    self.nIndex = nIndex
    self.bFinished = bFinished
    self.szFrame = MYQUEST_FRAME[bFinished].ICON
    self.szFrameBG = MYQUEST_FRAME[bFinished].BG
    self.bQuest = true
    self.szType = "MyQuest"

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgTaskBg, not bFinished)
    UIHelper.SetString(self.LabelTask, nIndex)
    UIHelper.SetVisible(self.ImgNormaliconBg, bFinished)
    UIHelper.SetSpriteFrame(self.ImgNormaliconBg, self.szFrameBG)
end

function UIMiddleMapSignButton:SetPQ(tbMark, tbInfo, tPoint)
    self.nPQID = tbMark.dwID
    self.tbInfo = tbInfo
    self.tPoint = tPoint
    self.bPQ = true
    self.szName = UIHelper.GBKToUTF8(tbInfo.szTitle)
    self.szType = "PQ"
    self.bHideInList = tbInfo.bHideInList

    self.szFrame = MapMgr.GetMapDynamicImage(tbMark.nType)

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    -- UIHelper.SetSpriteFrame(self.ImgNormaliconBg, PQ_FRAME.BG)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)

    local szMobileAreaImagePath = tbInfo.szMobileAreaImagePath
    UIHelper.SetVisible(self.ImgRange, szMobileAreaImagePath ~= "")
    if szMobileAreaImagePath ~= "" then
        UIHelper.SetSpriteFrame(self.ImgRange, szMobileAreaImagePath)
        UIHelper.SetScale(self.ImgRange, tbInfo.fScale, tbInfo.fScale)
    end
end

function UIMiddleMapSignButton:SetMapMark(szName, tPoint)
    self.tPoint = tPoint
    self.szName = szName
    self.szType = "MapMark"
    self.szFrame = "UIAtlas2_Map_MapIcon_img_location1.png"

    -- UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.WidgetPosition, true)
end

function UIMiddleMapSignButton:SetActivitySymbolMark(szName, tPoint)
    self.tPoint = tPoint
    self.szName = szName
    self.szType = "ActivitySymbolMark"
    self.szFrame = "UIAtlas2_Map_MapIcon_img_Baoxiang.png"

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
end

function UIMiddleMapSignButton:SetBattleFieldMark(tbInfo, tPoint, tArg, nState)
    local szTip = GBKToUTF8(ParseTextHelper.ParseNormalText(tbInfo.szTip))
    local szImgPath = MapMgr.GetBattleMarkImage(nState)
    if tbInfo.bArgTip then
        szTip = FormatString(szTip, unpack(tArg))
    end
    local tbTip = string.split(szTip, "\n")

    self.tbInfo = tbInfo
    self.tPoint = tPoint
    self.szName = UIHelper.GBKToUTF8(tbInfo.szTitle)
    self.szType = "BattleFieldMark"
    self.szFrame = szImgPath
    self.szDesc = tbTip[2] or ""


    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame, false)
    local nScale = 1.5 * tbInfo.fMobileScale
    UIHelper.SetScale(self.ImgNormalicon, nScale, nScale)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)

    UIHelper.SetTouchEnabled(self.TogSign, self.szName ~= "" and self.szName ~= "兵俑")
end

function UIMiddleMapSignButton:SetDeath()
    self.szName = g_tStrings.STR_DEATH_POSITION
    self.szType = "Death"
    self.szFrame = DEATH_FRAME.ICON
    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetSpriteFrame(self.ImgNormaliconBg, DEATH_FRAME.BG)
end

function UIMiddleMapSignButton:SetTeammate(szName)
    self.szName = GBKToUTF8(szName)
    self.szType = "Teammate"
    self.szFrame = TEAMMATE_FRAME.ICON
    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    -- UIHelper.SetSpriteFrame(self.ImgNormaliconBg, DEATH_FRAME.BG)
end

function UIMiddleMapSignButton:SetCraft(nCraftID)
    UIHelper.SetEnable(self.TogSign, false)
    self.bNotTurnMainMap = true
    local tab = MapHelper.GetMiddleMapCraftIconTab(nCraftID)
    if tab then
        UIHelper.SetSpriteFrame(self.ImgNormalicon, tab.szFrame)

        if tab.szBgFrame ~= '' then
            UIHelper.SetSpriteFrame(self.ImgNormaliconBg, tab.szBgFrame)
        else
            UIHelper.SetVisible(self.ImgNormaliconBg, false)
        end
    end
end

function UIMiddleMapSignButton:SetTag(tInfo)
    self.tbInfo = tInfo
    self.szName = tInfo.szName

    tInfo.nIconID = tInfo.nIconID or 1

    local tab = MapHelper.GetMiddleMapTagIconTab(tInfo.nIconID)
    self.szFrame = tab.szFrame
    if tab then
        UIHelper.SetSpriteFrame(self.ImgNormalicon, tab.szFrame)
        UIHelper.SetSpriteFrame(self.ImgNormaliconBg, tab.szBgFrame)
    end
    local bShowBG = tab.szBgFrame ~= ""
    UIHelper.SetVisible(self.ImgNormaliconBg, bShowBG)
end

function UIMiddleMapSignButton:SetCar(tbInfo)
    self.tbInfo = tbInfo
    self.tbCommand = MapMgr.GetMarkInfoByTypeID(14)
    self.tPoint = {tbInfo.nX,tbInfo.nY, Scene_GetFloor(tbInfo.nX, tbInfo.nY)}
    self.szFrame = UIHelper.GBKToUTF8(self.tbCommand.szMobileImage)
    self.szName = "摧城车"
    self.szType = "BoardCar"

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
end

function UIMiddleMapSignButton:SetBoardNPC(tbInfo)
    self.tbInfo = tbInfo
    self.tPoint = {tbInfo.nX, tbInfo.nY, Scene_GetFloor(tbInfo.nX, tbInfo.nY)}
    self.szFrame = UIHelper.GBKToUTF8(tbInfo.szMobileImage)
    self.szName =  ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tbInfo.szTip))
    self.szType = "BoardNPC"
    self.szDesc = ""

    local nHpPercentage = tbInfo.nHpPercentage
    local nHurtEffect = tbInfo.nHurtEffect
    local bShowHp = nHpPercentage and nHpPercentage ~= 0 and
        (not self.bIsMapPvp or (CommandBaseData.IsCommanderExisted() and CommandBaseData.IsCommandModeCanBeEntered()))

    local bShowHurt = nHurtEffect and nHurtEffect ~= 0
    UIHelper.SetVisible(self.WidgetSchedule, bShowHp)
    UIHelper.SetVisible(self.WidgetVulnerability, bShowHurt)
    if bShowHp then
        UIHelper.SetColor(self.SliderSchedule, HP_COLOR)
        UIHelper.SetProgressBarPercent(self.SliderSchedule, nHpPercentage)
        -- UIHelper.SetString(self.LabelScheduleNum, tostring(nHpPercentage) .. "%")
        UIHelper.SetVisible(self.LabelScheduleNum, false)--不显示血量百分比
        self.szDesc = self.szDesc .. string.format("当前血量：%s", nHpPercentage) .. "%"
    end

    if bShowHurt then
        UIHelper.SetString(self.LabelVulnerability, nHurtEffect .. "%")
        local szNewLine = (nHpPercentage and nHpPercentage ~= 0) and "\n" or ""
        self.szDesc = self.szDesc .. szNewLine .. string.format("当前易伤：%s", nHurtEffect) .. "%"
    end

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
end

function UIMiddleMapSignButton:SetNpcBeAttacked(tbInfo)
    self.tbInfo = tbInfo
    self.tPoint = {tbInfo.nX, tbInfo.nY, Scene_GetFloor(tbInfo.nX, tbInfo.nY)}
    self.szFrame = ""
    self.szName = ""
    self.szType = "BoardNPCBeAttacked"

    UIHelper.SetVisible(self.WidgteFighting, true)
    UIHelper.SetTouchEnabled(self.TogSign, false)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
end

function UIMiddleMapSignButton:SetTeamSignPost()
    self.szType = "TeamSignPost"
    UIHelper.SetTouchEnabled(self.TogSign, false)
    UIHelper.SetVisible(self.Eff_YaoLing, true)
end


function UIMiddleMapSignButton:SetRedPoint()
    self.szFrame = REPOINT_FRAME.ICON
    self.szType = "RedPoint"

    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame, false)
    UIHelper.SetTouchEnabled(self.TogSign, false)
end

function UIMiddleMapSignButton:SetProportion(nGoodCount, nEvilCount)
    self.szType = "Proportion"

    nGoodCount = nGoodCount or 0
    nEvilCount = nEvilCount or 0
    UIHelper.SetVisible(self.LayoutProportion, nGoodCount > 0 or nEvilCount > 0)
    UIHelper.SetString(self.LabelBlue, nGoodCount)
    UIHelper.SetString(self.LabelRed, nEvilCount)
    UIHelper.LayoutDoLayout(self.LayoutProportion)
end

function UIMiddleMapSignButton:SetHuntEvent(tbEventInfo, tbMark, tPoint)
    local tbInfo = Table_GetMapDynamicDataByID(tbEventInfo.nDynamicdataID)
    self.szName = UIHelper.GBKToUTF8(tbInfo.szTitle)
    self.szType = "HuntEvent"
    self.szFrame = MapMgr.GetMapDynamicImage(tbMark.nType)
    self.tPoint = tPoint
    self.szDesc = MapMgr.GetHuntInfoTip(tbEventInfo)
    self.nTime = nil
    self.bNotHuntTip = tbInfo.bNotHuntTip
    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
    local szMobileAreaImagePath = tbInfo.szMobileAreaImagePath
    UIHelper.SetVisible(self.ImgRange, szMobileAreaImagePath ~= "")
    if szMobileAreaImagePath ~= "" then
        UIHelper.SetSpriteFrame(self.ImgRange, szMobileAreaImagePath)
        UIHelper.SetScale(self.ImgRange, tbInfo.fScale, tbInfo.fScale)
    end
    local function AppendEventDetail(value, szType)
        if not value or not szType then
            return
        end

        UIHelper.SetVisible(self.ImgIcon, false)
        UIHelper.SetVisible(self.ImgVulnerabilityBg, false)
        UIHelper.SetPositionX(self.LabelVulnerability, -40)
        if szType == "Boss" or szType == "Progress" then
            UIHelper.SetVisible(self.WidgetSchedule, true)
            UIHelper.SetColor(self.SliderSchedule, HP_COLOR)
            UIHelper.SetProgressBarPercent(self.SliderSchedule, value)
        elseif szType == "Count" or szType == "Fraction" then
            UIHelper.SetVisible(self.ImgIcon, true)
            UIHelper.SetSpriteFrame(self.ImgIcon, IMG_MIDDLEMAP_HUNTEVENT_PEOPLE)
            UIHelper.SetVisible(self.WidgetVulnerability, true)
            UIHelper.SetString(self.LabelVulnerability, UIHelper.GBKToUTF8(value))
            UIHelper.SetVisible(self.ImgVulnerabilityBg, true)
            UIHelper.SetPositionX(self.LabelVulnerability, -10)
        elseif szType == "Time" or szType == "PreTime" then
            local nLeftTime = value - GetCurrentTime()
            self.nTime = value
            if nLeftTime < 0 then
                nLeftTime = 0
            end
            local szText = UIHelper.GetCoolTimeText(nLeftTime)
            local color = UIHelper.GetLabelTimeColor(nLeftTime)

            UIHelper.SetVisible(self.WidgetVulnerability, true)
            UIHelper.SetString(self.LabelVulnerability, szText)
            UIHelper.SetColor(self.LabelVulnerability, color)
        end
    end

    local function UpdateHuntEventType()
        if tbEventInfo.tIconValue then
            for _, v in pairs(tbEventInfo.tIconValue) do
                for szType, val in pairs(v) do
                    AppendEventDetail(val, szType)
                end
            end
        end
    end

    local function RefreshEventTime()
        if self.nTime then
            local nLeftTime = self.nTime - GetCurrentTime()
            if nLeftTime < 0 then
                nLeftTime = 0
            end
            local szText = UIHelper.GetCoolTimeText(nLeftTime)
            local color = UIHelper.GetLabelTimeColor(nLeftTime)
            UIHelper.SetVisible(self.WidgetVulnerability, true)
            UIHelper.SetString(self.LabelVulnerability, szText)
            UIHelper.SetColor(self.LabelVulnerability, color)
        end
    end

    UpdateHuntEventType()

    Timer.AddFrameCycle(self, 3, function()
        RefreshEventTime()
    end)
end

function UIMiddleMapSignButton:SetKillerPos(tbKillerInfo)
    self.szType = "KillPos"
    self.szName = UIHelper.GBKToUTF8(tbKillerInfo.szName)
    self.tPoint = {tbKillerInfo.x, tbKillerInfo.y, tbKillerInfo.z}
    self.szFrame = "Resource_Minimap_Minimap_419.png"

    local function GetKillerTip()
        local szName = self.szName
        local dwTongID = tbKillerInfo.dwTongID
        local nCamp = tbKillerInfo.nCamp
        local szTip = GetFormatText(self.szName .. "\n")
        if nCamp then
            szTip = szTip .. GetFormatText(FormatString(g_tStrings.ACHIEVEMENT_RANK_GUILD_CAMP, g_tStrings.STR_CAMP_TITLE[nCamp]))
        end
        if dwTongID and dwTongID ~= 0 then
            local szTongName = UIHelper.GBKToUTF8(GetTongClient().ApplyGetTongName(dwTongID))
            szTip = szTip .. GetFormatText(FormatString(g_tStrings.ACHIEVEMENT_RANK_GUILD, szTongName))
        end
        return szTip
    end
    self.szDesc = GetKillerTip()
    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
end

function UIMiddleMapSignButton:SetExplore(tbInfo)
    self.szType = "Explore"
    self.szName = UIHelper.GBKToUTF8(tbInfo.szName)
    self.tPoint = {tbInfo.nX, tbInfo.nY, tbInfo.nZ}
    self.szDesc = self:GetExploreTip(tbInfo)
    self.nState = tbInfo.nState
    self.szFrame = tbInfo.szMBFrame
    self.nType = tbInfo.nSubType
    self.fShowScale = tbInfo.fShowScale or 1
    UIHelper.SetSpriteFrame(self.ImgNormalicon, self.szFrame)
    UIHelper.SetVisible(self.ImgNormaliconBg, false)
    UIHelper.SetVisible(self.ImgExploreDone, self.nState >= MAP_EXPLORE_STATE.FINISH)
    UIHelper.SetNodeGray(self._rootNode, self.nState == MAP_EXPLORE_STATE.NOT_EXPLORE, true)
end

function UIMiddleMapSignButton:GetExploreTip(tInfo)
    local szTip = ""
    if not tInfo then
        return szTip
    end
    szTip = GetFormatText(UIHelper.GBKToUTF8(tInfo.szTip))
    if tInfo.nState ~= MAP_EXPLORE_STATE.NOT_EXPLORE then
        return szTip
    end
    szTip = szTip .. GetFormatText("("..g_tStrings.STR_ARENA_LOCK..")\n", nil, 255, 130, 136)

    local nIndex = 1
    local dwFameID, nLevel = tInfo.dwFameID, tInfo.nFameLevel
    local szFameName = Table_GetFameName(dwFameID)
    if szFameName ~= "" and nLevel ~= 0 then
        local nNowLevel = GDAPI_GetFameLevelInfo(GetClientPlayer(), dwFameID)
        local szFameTip = FormatString(g_tStrings.STR_EXPLORE_UNLOCK_FAME, UIHelper.GBKToUTF8(szFameName), nLevel)
        if nNowLevel < nLevel then
            szTip = szTip .. GetFormatText(nIndex .. "."..szFameTip)
            nIndex = nIndex + 1
        end
    end

    local szPreID       = tInfo.szPreID
    local tList         = SplitString(szPreID, ";")
    local bHasNotFinish = false
    local szPreTip = ""
    for _, v in pairs(tList) do
        local dwID = tonumber(v)
        local tInfo = Table_GetMapExploreTypeByID(dwID)
        if tInfo then
            local nState = MapHelper.GetMapExploreState(tInfo)
            local nR, nG, nB = 149, 255, 149
            if nState < MAP_EXPLORE_STATE.FINISH then
                nR, nG, nB = 182, 212, 220
            end
            szPreTip = szPreTip .. GetFormatText(g_tStrings.STR_SPLIT_DOT .. UIHelper.GBKToUTF8(tInfo.szName) .. "\n", nil, nR, nG, nB)
            bHasNotFinish = bHasNotFinish or nState < MAP_EXPLORE_STATE.FINISH
        end
    end

    if szPreTip ~= "" then
        szTip = szTip .. GetFormatText(nIndex .. "."..g_tStrings.STR_EXPLORE_FINISH_PRE_QUEST) .. szPreTip
        nIndex = nIndex + 1
    end
    return szTip
end

function UIMiddleMapSignButton:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self.TogSign, bSelected, bCallback and true or false)
end

function UIMiddleMapSignButton:UpdateTrace(nMapID)
    self.bTrace = MapMgr.IsNodeTraced(nMapID, self.tPoint)
end

function UIMiddleMapSignButton:DoAction()
    if self.fnDetailPanel then
        self.fnDetailPanel(self.bTrace)
    end
end

local function FormatName(szName, szKind)
    local szResName = ""
    local tbStr = {}
    if szKind and szKind ~= "" then
        table.insert(tbStr, szKind)
    end

    if szName and szName ~= "" then
        table.insert(tbStr, szName)
    end

    for nIndex, szName in ipairs(tbStr) do
        if nIndex ~= 1 then
            szResName = szResName .. "·" .. szName
        else
            szResName = szName
        end
    end

    return UIHelper.LimitUtf8Len(szResName, 13)
end

local function FormatName2(szName, szKind)
    if szKind and szKind ~= "" then
        szName = string.format("%s%s", szKind, szName)
    end
    return UIHelper.LimitUtf8Len(szName, 13)
end

function UIMiddleMapSignButton:GetTitle()
    if self.szType == "Transfer" then
        -- TODO
        return FormatName2(self.szName, "前往：")
    elseif self.szType == "Traffic" then
        return FormatName(self.szName)
    elseif self.szType == "Quest" or self.szType == "MyQuest" then
        return FormatName(QuestData.GetQuestName(self.nQuestID))
    elseif self.szType == "PQ" then
        return FormatName(self.szName)
    elseif self.szType == "BattleFieldMark" then
        return self.szName
    elseif self.szType == "MapMark" then
        return FormatName(self.szName)
    elseif self.szType == "Teammate" then
        return FormatName(self.szName)
    elseif self.szType == "Death" then
        return FormatName(self.szName)
    elseif self.szType == "HuntEvent" then
        return FormatName(self.szName)
    elseif self.szType == "KillPos" then
        return FormatName(self.szName)
    elseif self.szType == "Explore" then
        return FormatName(self.szName)
    else
        return FormatName(self.szName or "", self.tbInfo and self.tbInfo.szKind or "")
    end
end

function UIMiddleMapSignButton:IsTeamTag()
    return self.tbInfo.nIconID == 8
end

function UIMiddleMapSignButton:GetNPCInfo()
    local tbInfo = {}
    local szName = ""
    local szType = ""
    local szImgType = ""
    local tbPoint = ""

    if self.szType == "Transfer" then
        return nil
    elseif self.szType == "Traffic" then
        local tbPoint = self.tbInfo.tbPoint
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = tbPoint, szTraceImg = self.szFrame}
    elseif self.szType == "Wanted" then
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = self.tbPoint, szTraceImg = self.szFrame}
    elseif self.szType == "MyQuest" then
        return {szName = QuestData.GetQuestName(self.nQuestID), szType = "", szImgType = self.szFrame, tbPoint = tbPoint, szTraceImg = self.szFrame}
    elseif self.szType == "Quest" then
        local tbPoint = self.tPoint
        return {szName = QuestData.GetQuestName(self.nQuestID), szType = "", szImgType = self.szFrame, tbPoint = tbPoint, szTraceImg = self.szFrame}
    elseif self.szType == "PQ" then
        local tbPoint = self.tPoint
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = tbPoint, szTraceImg = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_else"}
    elseif self.szType == "BattleFieldMark" then
        local tbPoint = self.tPoint
        return {szName = self.szName, szType = "", szDesc = self.szDesc, szImgType = self.szFrame, tbPoint = tbPoint, szTraceImg = self.szFrame}
    elseif self.szType == "MapMark" then
        local tbPoint = self.tPoint
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = tbPoint, szTraceImg = self.szFrame}
    elseif self.szType == "Teammate" then
        return nil
    elseif self.szType == "Death" then
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = MapMgr.GetDeathPosition(), szTraceImg = self.szFrame}
    elseif self.szType == "BoardNPCBeAttacked" then
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    elseif self.szType == "BoardNPC" then
        return {szName = self.szName, szType = "", szDesc = self.szDesc, szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    elseif self.szType == "BoardCar" then
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    elseif self.szType == "SearchNpc" then
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    elseif self.szType == "BossInfo" then
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    elseif self.szType == "Inscription" then
        szName = self.szName
        szType = self.tbInfo.szKind
        return {szName = self.szName, szType = szType, szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame, bButtonGray = self.bButtonGray}
    elseif self.szType == "ActivitySymbolMark" then
        return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    elseif self.szType == "HuntEvent" then
        if self.bNotHuntTip then
            return {szName = self.szName, szType = "", szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
        else
            return {szName = self.szName, szType = "", szDesc = self.szDesc, szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
        end
    elseif self.szType == "KillPos" then
         return {szName = self.szName, szType = "", szDesc = self.szDesc, szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    elseif self.szType == "Explore" then
        return {szName = self.szName, szType = "", szDesc = self.szDesc, szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    else
        szName = self.szName
        szType = self.tbInfo.szKind
        return {szName = self.szName, szType = szType, szImgType = self.szFrame, tbPoint = self.tPoint, szTraceImg = self.szFrame}
    end
end

function UIMiddleMapSignButton:GetBoardInfo()
    local tbInfo = {}
    tbInfo.nType = self.tbInfo.nType
    tbInfo.nX = self.tPoint.nX
    tbInfo.nY = self.tPoint.nY
    return tbInfo
end

function UIMiddleMapSignButton:CanShow()
    if self.szType == "Death" then
        return MapMgr.GetDeathPosition() ~= nil
    end
    return true
end

function UIMiddleMapSignButton:IsButtonGray()
    if self.bButtonGray then return self.bButtonGray end
    return false
end

function UIMiddleMapSignButton:IsRedPointQuest()
    local tbRedPoint = MapMgr.GetRedPointQuestInfo(self.nMapID)
    if not tbRedPoint then return false end

    return self.szType == "MyQuest" and self.nQuestID == tbRedPoint[1]
end

function UIMiddleMapSignButton:CanAddToNeiborList()
    if self.bHideInList then return false end
    if self.szType == "BoardNPCBeAttacked" or self.szType == "SearchNpc" or self.szType == "TeamSignPost" then
        return false
    end

    if self.szType == "BattleFieldMark" and self.szName == "" then
        return false
    end

    return UIHelper.GetHierarchyVisible(self._rootNode)
end



return UIMiddleMapSignButton