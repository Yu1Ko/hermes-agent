-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiniGameJigsawPanel
-- Date: 2025-09-29 19:26:32
-- Desc: ?
-- ---------------------------------------------------------------------------------
--Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv1.png
local UIMiniGameJigsawPanel = class("UIMiniGameJigsawPanel")
local EPS = 20
local DELAY_HIDE_CORRECT = 100
local MAX_FAILED_TIMES = 5
local DELAY_HIDE_HINT = 5
local tbFullImgList = {
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv1.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv1.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv2.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv2.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv3.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv3.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv4.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv4.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv5.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv5.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv6.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv6.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv7.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv7.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv8.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv8.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv9.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv9.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv10.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Full_Lv10.png",
}

local tbBreakImgList = {
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv1.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv1.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv2.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv2.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv3.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv3.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv4.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv4.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv5.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv5.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv6.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv6.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv7.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv7.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv8.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv8.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv9.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv9.png",
    ["ui/Image/UItimate/MiniGame/Jigsaw/JigsawBg_Lv10.tga"] = "Resource/UItimate/MiniGame/Jigsaw/JigsawBg_Lv10.png",
}

local function ConvertPiecePath(path, nIndex)
    local sub_path = path:match("[/\\]?UItimate.*/(.-)%.UITex$")
    local dir_path = path:match("[/\\]?(UItimate.*/)") or ""
    dir_path = dir_path and dir_path:gsub("/", "_"):sub(1, -2) or ""
    local filename = path:match(".*/(.-)%.UITex$")
    local prefix = dir_path ~= "" and ("Resource_" .. dir_path) or "Resource"
    return string.format("%s_%s_%d.png", prefix, filename, nIndex - 1)
end

function UIMiniGameJigsawPanel:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tInfo)
    Timer.AddCycle(self, 1/10, function ()
        if self.nStartTime then
            self:UpdateTime()
        end
        if not IsTableEmpty(self.tShowHintItem) then
            if self.nHintHideTime and GetCurrentTime() >= self.nHintHideTime then
                for _, v in pairs(self.tShowHintItem) do
                    UIHelper.SetVisible(v, false)
                end
                self.tShowHintItem = {}
            end
        end
    end)
end

function UIMiniGameJigsawPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIMiniGameJigsawPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIMiniGameJigsawPanel:RegEvent()
    Event.Reg(self, EventType.OnMiniGameUpdateJigsaw, function (tInfo)
        self:Update(tInfo)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        if self.tbMissingPartScript then
            for k, tbScript in pairs(self.tbMissingPartScript) do
                self:UpdatePartMod(tbScript)
            end
        end
    end)
end

function UIMiniGameJigsawPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function IsSamePiece(tPiece1, tPiece2)
    if not tPiece1 or not tPiece2 then
        return false
    end
    if tPiece1.nType == tPiece2.nType and tPiece1.nIndex == tPiece2.nIndex then
        return true
    end
    return false
end

function UIMiniGameJigsawPanel:UpdateInfo(tInfo)
    self:Init(tInfo)
    self:UpdateView()
end

function UIMiniGameJigsawPanel:Init(tInfo)
    if tInfo.bClearData then
        self:UnInitData()
    end
    self.tInfo         = tInfo
    self.tJigsawUIInfo = Table_GetJigsawInfo(tInfo.nType) or {}
    self.nStartTime    = GetCurrentTime()
    self.nFailedTimes  = 0
    self.tShowHintItem = {}
    self.nHintHideTime = 0
    self.nHintIndex    = 0
end

function UIMiniGameJigsawPanel:GetCorrectPos(nType, nIndex)
    local tJigsawUIInfo = self.tJigsawUIInfo
    local tPieces = tJigsawUIInfo.tPieces or {}
    local tPiece = nil
    for _, v in pairs(tPieces) do
        if IsSamePiece(v, {nType = nType, nIndex = nIndex}) then
            tPiece = v
            break
        end
    end
    if not tPiece then
        return 0, 0
    end
    return tPiece.nX, tPiece.nY
end

function UIMiniGameJigsawPanel:UnInitData()
    self.tInfo         = nil
    self.tJigsawUIInfo = nil
    self.nStartTime    = nil
    self.nFailedTimes  = nil
    self.tShowHintItem = nil
    self.nHintHideTime = nil
    self.nHintIndex    = nil
end

function UIMiniGameJigsawPanel:UpdateTime()
    if not self.nStartTime then
        return
    end

    local nTime = GetCurrentTime() - self.nStartTime
    local szTime = UIHelper.GetCoolTimeText(nTime)
    --设置倒计时
    UIHelper.SetString(self.LabelTime, szTime)
end

function UIMiniGameJigsawPanel:UpdateView()
    self:UpdatePic()
    self:UpdatePieces()
    self:UpdateMissingPart()
end

function UIMiniGameJigsawPanel:UpdatePic()
    local tInfo = self.tJigsawUIInfo.tUIInfo
    if not tInfo then
        return
    end
    if tInfo.szFullImagePath ~= "" then
        UIHelper.SetTexture(self.ImgFullPuzzlePainting, tbFullImgList[tInfo.szFullImagePath])
    end
    if tInfo.szBreakImagePath ~= "" then
        UIHelper.SetTexture(self.ImgBreakPuzzlePainting, tbBreakImgList[tInfo.szBreakImagePath])
    end
    local szNum = Conversion2ChineseNumber(tInfo.nType)
    local szName = UIHelper.GBKToUTF8(tInfo.szName)
    szName = szName:gsub("《", "︽"):gsub("》", "︾")
    szName = szName:gsub("（", "︵"):gsub("）", "︶")
    UIHelper.SetString(self.LabelContent, UIHelper.GBKToUTF8(tInfo.szAuthor) .. " " .. szName)
    UIHelper.SetString(self.LabelContentDone, UIHelper.GBKToUTF8(tInfo.szAuthor) .. " " .. szName)
    UIHelper.SetString(self.LabelTitle, FormatString(g_tStrings.STR_MINI_GAME_LEVEL, szNum))
    UIHelper.SetVisible(self.ImFullPuzzleBg, self.bFinish)
    UIHelper.SetVisible(self.ImgBreakPuzzleBg, not self.bFinish)
    UIHelper.SetVisible(self.LabelTime, not self.bFinish)
    UIHelper.SetVisible(self.ScrollViewPuzzlePiece, not self.bFinish)
    UIHelper.SetVisible(self.WidgetAnchorTime, not self.bFinish)
    if self.bFinish then
        self.nStartTime = nil
    end
end

function UIMiniGameJigsawPanel:UpdatePieces()
    local tPiecesInfo = self.tJigsawUIInfo.tPieces or {}
    UIHelper.RemoveAllChildren(self.ScrollViewPuzzlePiece)
    self.tbPeicesScript = {}
    for i, tInfo in pairs(tPiecesInfo) do
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPuzzlePiece, self.ScrollViewPuzzlePiece)
        tbScript.tInfo = tInfo
        self.tbPeicesScript[i] = tbScript
        self:UpdatePieceMod(tbScript)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPuzzlePiece)
end

local function GetLogicDist2D(vPos1, vPos2)
    return math.sqrt((vPos1[1] - vPos2[1]) * (vPos1[1] - vPos2[1]) + (vPos1[2] - vPos2[2]) * (vPos1[2] - vPos2[2]))
end

function UIMiniGameJigsawPanel:UpdatePieceMod(tbScript)
    if not tbScript or not tbScript.tInfo then
        return
    end

    local tInfo       = tbScript.tInfo
    if tInfo.szImagePath ~= "" then
        local szPath = ConvertPiecePath(tInfo.szImagePath, tInfo.nIndex)
        if szPath then
            UIHelper.SetSpriteFrame(tbScript.ImgPuzzle, szPath)
        end
    end
    if tInfo.szHintPath ~= "" then
        local szPath = ConvertPiecePath(tInfo.szHintPath, tInfo.nIndex)
        if szPath then
            UIHelper.SetSpriteFrame(tbScript.ImgHintPuzzle, szPath)
        end
    end
    UIHelper.SetSwallowTouches(self.ScrollViewPuzzlePiece, true)
    UIHelper.BindUIEvent(tbScript.BtnPuzzlePiece, EventType.OnTouchBegan, function(btn, nX, nY)
        tbScript.bSuccess = true
        self:UpdatePieceModState(tbScript)
        self.tbCurSelectPieceScript = tbScript
        if self.tbCurDragScript then
            UIHelper.RemoveFromParent(self.tbCurDragScript._rootNode)
            self.tbCurDragScript = nil
        end
        local tbDragScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPuzzlePiece, self.WidgetDragPiece)
        tbDragScript.tInfo = tbScript.tInfo
        self.tbCurDragScript = tbDragScript
        self:UpdateDragPeiceMod(tbDragScript, nX, nY)
        
    end)

    UIHelper.BindUIEvent(tbScript.BtnPuzzlePiece, EventType.OnTouchMoved, function(btn, nX, nY)
        nX, nY = UIHelper.ConvertToNodeSpace(self.WidgetDragPiece, nX, nY)
        UIHelper.SetPosition(self.tbCurDragScript._rootNode, nX, nY)
    end)

    UIHelper.BindUIEvent(tbScript.BtnPuzzlePiece, EventType.OnTouchEnded, function(btn, nX, nY)
        if self.tbCurSelectPieceScript then
            self.tbCurSelectPieceScript.bSuccess = false
            self:UpdatePieceModState(self.tbCurSelectPieceScript)
        end
        UIHelper.RemoveFromParent(self.tbCurDragScript._rootNode)
        self.tbCurDragScript = nil
    end)

    UIHelper.BindUIEvent(tbScript.BtnPuzzlePiece, EventType.OnTouchCanceled, function(btn, nX, nY)
        
        local tPieceInfo = self.tbCurDragScript.tInfo
        if IsSamePiece(tPieceInfo, tbScript.tInfo) then
            local nX, nY = UIHelper.GetWorldPosition(self.tbCurDragScript._rootNode)
            nX, nY = UIHelper.ConvertToNodeSpace(self.WidgetMissingPart, nX, nY)
            local nCorrectX, nCorrectY = self:GetCorrectPos(tbScript.tInfo.nType, tbScript.tInfo.nIndex)
            nCorrectX, nCorrectY  = nCorrectX + 3, 445 - nCorrectY
            local nCurX, nCurY = nX, nY
            local tInfo = {
                nType = tPieceInfo.nType,
                nIndex = tPieceInfo.nIndex,
                nX = nX - 3,
                nY = 445 - nY,
            }
            local nDistance = GetLogicDist2D({nCurX, nCurY}, {nCorrectX, nCorrectY})
            UIHelper.RemoveFromParent(self.tbCurDragScript._rootNode)
            if nDistance > EPS then
                self.nFailedTimes = self.nFailedTimes + 1
                if self.nFailedTimes >= MAX_FAILED_TIMES then
                    self.tHintInfo = {nType = tPieceInfo.nType, nIndex = tPieceInfo.nIndex}
                    self:ShowHint()
                end
                self.tbCurSelectPieceScript.bSuccess = false
                self:UpdatePieceModState(self.tbCurSelectPieceScript)
                return
            end
            self.tbCurDragScript = nil
            RemoteCallToServer("On_PinTu_Check", tInfo)
        end
    end)
end

function UIMiniGameJigsawPanel:UpdateDragPeiceMod(tbScript, nX, nY)
    if not tbScript or not tbScript.tInfo then
        return
    end
    local tInfo       = tbScript.tInfo
    if tInfo.szImagePath ~= "" then
        local szPath = ConvertPiecePath(tInfo.szImagePath, tInfo.nIndex)
        if szPath then
            UIHelper.SetSpriteFrame(tbScript.ImgPuzzle, szPath)
        end
    end
    nX, nY = UIHelper.ConvertToNodeSpace(self.WidgetDragPiece, nX, nY)
    UIHelper.SetPosition(self.tbCurDragScript._rootNode, nX, nY)
end

function UIMiniGameJigsawPanel:UpdateMissingPart()
    local tPiecesInfo = self.tJigsawUIInfo.tPieces or {}
    UIHelper.RemoveAllChildren(self.WidgetMissingPart)
    self.tbMissingPartScript = {}
    for i, tInfo in pairs(tPiecesInfo) do
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPuzzlePiece, self.WidgetMissingPart)
        tbScript.tInfo = tInfo
        self.tbMissingPartScript[i] = tbScript
        self:UpdatePartMod(tbScript)
    end
end

function UIMiniGameJigsawPanel:UpdatePartMod(tbScript)
    if not tbScript or not tbScript.tInfo then
        return
    end
    local tInfo       = tbScript.tInfo
    if tInfo.szImagePath ~= "" then
        local szPath = ConvertPiecePath(tInfo.szImagePath, tInfo.nIndex)
        if szPath then
            UIHelper.SetSpriteFrame(tbScript.ImgPuzzle, szPath)
        end
    end
    if tInfo.szCorrectPath ~= "" then
        local szPath = ConvertPiecePath(tInfo.szCorrectPath, tInfo.nIndex)
        if szPath then
            UIHelper.SetSpriteFrame(tbScript.ImgHoverPuzzle, szPath)
        end
    end
    if tInfo.szHintPath ~= "" then
        local szPath = ConvertPiecePath(tInfo.szHintPath, tInfo.nIndex)
        if szPath then
            UIHelper.SetSpriteFrame(tbScript.ImgHintPuzzle, szPath)
        end
    end
    --设置位置
    local size = UIHelper.GetCurResolutionSize()
    Timer.AddFrame(self, 2, function ()
        UIHelper.SetPosition(tbScript._rootNode, tInfo.nX + 3, 445 - tInfo.nY)
    end)
    self:UpdatePartModState(tbScript)
end

function UIMiniGameJigsawPanel:RefreshMissingPart(tResult)
    for k, tbScript in pairs(self.tbMissingPartScript) do
        if tbScript and IsSamePiece(tbScript.tInfo, tResult) then
            tbScript.bSuccess = tResult.bSuccess
            self:UpdatePartModState(tbScript)
        end
    end

    for k, tbPieceScript in pairs(self.tbPeicesScript) do
        if tbPieceScript and IsSamePiece(tbPieceScript.tInfo, tResult) then
            tbPieceScript.bSuccess = tResult.bSuccess
            self:UpdatePieceModState(tbPieceScript)
        end
    end
end

function UIMiniGameJigsawPanel:UpdatePartModState(tbScript)
    if not tbScript then
        return
    end

    UIHelper.SetVisible(tbScript.ImgPuzzle, tbScript.bSuccess)
    if tbScript.bSuccess then
        UIHelper.SetVisible(tbScript.ImgHoverPuzzle, true)
        Timer.Add(self, 1, function ()
            UIHelper.SetVisible(tbScript.ImgHoverPuzzle, false)
        end)
    end
end

function UIMiniGameJigsawPanel:UpdatePieceModState(tbScript)
    if not tbScript then
        return
    end
    UIHelper.SetVisible(tbScript.ImgPuzzle, not tbScript.bSuccess)
    UIHelper.SetVisible(tbScript.ImgHoverPuzzle, false)
    UIHelper.SetVisible(tbScript.BtnPuzzlePiece, not tbScript.bSuccess or UIHelper.GetVisible(tbScript.ImgHintPuzzle))
end

function UIMiniGameJigsawPanel:HideHint()
    for _, v in pairs(self.tShowHintItem) do
        UIHelper.SetVisible(v, false)
    end

    self.tShowHintItem = {}
    self.tHintInfo = nil
end

function UIMiniGameJigsawPanel:ShowHint()
    local tbHintPieceScript = nil
    for k, tbScript in pairs(self.tbPeicesScript) do
        if tbScript and IsSamePiece(tbScript.tInfo, self.tHintInfo) then
            tbHintPieceScript = tbScript
            break
        end
    end

    if not tbHintPieceScript then
        return
    end

    local tbHintPartScript = nil
    for k, tbScript in pairs(self.tbMissingPartScript) do
        if tbScript and IsSamePiece(tbScript.tInfo, self.tHintInfo) then
            tbHintPartScript = tbScript
            break
        end
    end

    if not tbHintPartScript then
        return
    end

    for _, v in pairs(self.tShowHintItem) do
        UIHelper.SetVisible(v, false)
    end

    UIHelper.SetVisible(tbHintPieceScript.ImgHintPuzzle, true)
    UIHelper.SetVisible(tbHintPartScript.ImgHintPuzzle, true)
    self.tShowHintItem = {tbHintPieceScript.ImgHintPuzzle, tbHintPartScript.ImgHintPuzzle}
    self.nHintHideTime = GetCurrentTime() + DELAY_HIDE_HINT
end

function UIMiniGameJigsawPanel:Update(tResult)
    if not tResult then
        return
    end

    self:RefreshMissingPart(tResult)
    if tResult.bComplete then
        self.bFinish = tResult.bComplete
        self:UpdatePic()
    end

    if not tResult.bSuccess then
        self.nFailedTimes = self.nFailedTimes + 1
        if self.nFailedTimes >= MAX_FAILED_TIMES then
            self.tHintInfo = {nType = tResult.nType, nIndex = tResult.nIndex}
            self:ShowHint()
        end
    else
        self.nFailedTimes = 0
        self:HideHint()
    end
end

return UIMiniGameJigsawPanel