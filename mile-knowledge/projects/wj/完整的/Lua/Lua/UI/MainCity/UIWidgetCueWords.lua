-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCueWords
-- Date: 2025-12-15 09:51:15
-- Desc: DX CurWords功能接入 WidgetHintZhuZiGuoChang
-- ---------------------------------------------------------------------------------

local UIWidgetCueWords = class("UIWidgetCueWords")

local INI_TYPE = {
    CueWords_Tale = "CueWords_Tale", --短横排
    CueWords_Tale_FromR = "CueWords_Tale_FromR", --短竖排
    CueWords_Warn = "CueWords_Warn", --长横排
}

-- \ui\Scheme\Case\CueWords.txt - ImgStampFrame
local tStampFrameConvert = {
    [31] = "ImgRed1",
    [32] = "ImgYellow2",
    [33] = "ImgGreen1",
    [34] = "ImgRed2",
    [35] = "ImgYellow1",
    [36] = "ImgGreen2",
}

-----------------------------DataModel------------------------------
local DataModel = {}
local ALPHA_MAX = 255

function DataModel.Init(nKeepTime, tText, dwID)
    local tInfo                 = Table_GetCueWords(dwID)
    DataModel.tInfo             = tInfo
    DataModel.szIniName         = tInfo.szIni --CueWords_Tale/CueWords_Tale_FromR/CueWords_Warn
    -- DataModel.szIniFile         = StringConcat(szIniFile, tInfo.szIni, ".ini")
    DataModel.nKeepTime         = nKeepTime
    DataModel.nKeepTimeOrg      = nKeepTime
    
    DataModel.nFadeInTime       = tInfo.nFadeInTime
    DataModel.nFadeOutTime      = tInfo.nFadeOutTime
    DataModel.nFadeInTimeOrg    = tInfo.nFadeInTime
    DataModel.nFadeOutTimeOrg   = tInfo.nFadeOutTime
    DataModel.bTextFadeIn       = tInfo.bTextFadeIn
    DataModel.bTextRight        = tInfo.bTextRight
    DataModel.tText             = tText
    DataModel.nTextCount        = #tText
    DataModel.nTextFadeIn       = 0
    DataModel.fFadeOutScale     = ALPHA_MAX / DataModel.nFadeOutTime
    DataModel.fFadeInScale      = ALPHA_MAX / DataModel.nFadeInTime
    DataModel.nTextNextTime     = nil
end

function DataModel.UnInit()
    DataModel.tInfo             = nil
    DataModel.szIniName         = nil
    -- DataModel.szIniFile         = nil
    DataModel.nAllKeepTime      = nil
    DataModel.nKeepTime         = nil
    DataModel.nKeepTimeOrg      = nil
    DataModel.nFadeInTime       = nil
    DataModel.nFadeOutTime      = nil
    DataModel.nFadeInTimeOrg    = nil
    DataModel.nFadeOutTimeOrg   = nil
    DataModel.bTextFadeIn       = nil
    DataModel.tText             = nil
    DataModel.nTextCount        = nil
    DataModel.nTextFadeIn       = nil
    DataModel.fFadeOutScale     = nil
    DataModel.fFadeInScale      = nil
    DataModel.nTextNextTime     = nil
end

function UIWidgetCueWords:OnEnter(nKeepTime, tText, szTitle, dwID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not nKeepTime or not tText or not szTitle or not dwID then
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    Timer.AddFrameCycle(self, 1, function()
        local nLogicFrameCount = GetLogicFrameCount()
        if nLogicFrameCount ~= self.nLogicFrameCount then
            self:UpdateFade()
            self.nLogicFrameCount = nLogicFrameCount
        end
    end)

    UIHelper.SetVisible(self._rootNode, true)
    DataModel.Init(nKeepTime, tText, dwID)
    self:UpdateInfo(szTitle)
end

function UIWidgetCueWords:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel.UnInit()
end

function UIWidgetCueWords:Clear()
    UIHelper.SetVisible(self.WidgetHintZhuZi1, false)
    UIHelper.SetVisible(self.WidgetHintZhuZi2, false)
    UIHelper.RemoveAllChildren(self.LayoutCircleContent)
    UIHelper.RemoveAllChildren(self.LayoutCircleContentVertical)
    UIHelper.RemoveAllChildren(self.LayoutCircleContent2)
    UIHelper.SetRichText(self.RichTextTitle1, "")
    UIHelper.SetRichText(self.RichTextTitle2, "")
    UIHelper.SetVisible(self.ImgGreen1, false)
    UIHelper.SetVisible(self.ImgRed1, false)
    UIHelper.SetVisible(self.ImgYellow1, false)
    UIHelper.SetVisible(self.ImgGreen2, false)
    UIHelper.SetVisible(self.ImgRed2, false)
    UIHelper.SetVisible(self.ImgYellow2, false)
    self.RichTextTitle = nil
    self.LayoutContent = nil
    self.CellPrefabID = nil
end

function UIWidgetCueWords:Close()
    self:Clear()
    DataModel.UnInit()
    Timer.DelAllTimer(self)
    UIHelper.SetVisible(self._rootNode, false)
end

function UIWidgetCueWords:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    
end

function UIWidgetCueWords:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCueWords:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCueWords:UpdateInfo(szTitle)
    local tInfo = DataModel.tInfo
    local szIniName = DataModel.szIniName

    self:Clear()

    if szIniName == INI_TYPE.CueWords_Tale then
        UIHelper.SetVisible(self.WidgetHintZhuZi1, true) -- tInfo.nImgFrame -> 29
        self.RichTextTitle = self.RichTextTitle1
        self.LayoutContent = self.LayoutCircleContent
        self.CellPrefabID = PREFAB_ID.WidgetHintZhuZiRichtextCell1
    elseif szIniName == INI_TYPE.CueWords_Tale_FromR then
        UIHelper.SetVisible(self.WidgetHintZhuZi1, true) -- tInfo.nImgFrame -> 29
        self.RichTextTitle = self.RichTextTitle1
        self.LayoutContent = self.LayoutCircleContentVertical
        self.CellPrefabID = PREFAB_ID.WidgetHintZhuZiRichtextCellVertical
    elseif szIniName == INI_TYPE.CueWords_Warn then
        UIHelper.SetVisible(self.WidgetHintZhuZi2, true) -- tInfo.nImgFrame -> 8
        self.RichTextTitle = self.RichTextTitle2
        self.LayoutContent = self.LayoutCircleContent2
        self.CellPrefabID = PREFAB_ID.WidgetHintZhuZiRichtextCell2
    end

    if tInfo.bShowImgStamp and tInfo.szImgStampPath ~= "" then
        local szStampNodeName = tStampFrameConvert[tInfo.nImgStampFrame]
        local imgStamp = szStampNodeName and self[szStampNodeName]
        UIHelper.SetVisible(imgStamp, true)
    end

    -- local hImgBg = hFrame:Lookup("", "Image_Bg")
    -- if hImgBg and tInfo.szImgPath ~= "" then
    --     hImgBg:FromUITex(tInfo.szImgPath, tInfo.nImgFrame)
    -- end

    if szTitle and szTitle ~= "" then
        -- UIHelper.SetRichText(self.RichTextTitle, UIHelper.AttachTextColor(UIHelper.GBKToUTF8(szTitle), "#ffffff"))
        UIHelper.SetRichText(self.RichTextTitle, UIHelper.GBKToUTF8(szTitle))
    end
end

function UIWidgetCueWords:SetShowText()
    if DataModel.bTextFadeIn then
        self:UpdateText()
    else
        for i = 1, #DataModel.tText do
            self:AppendAText(DataModel.tText[i], i)
        end
        UIHelper.LayoutDoLayout(self.LayoutContent)
    end
end

function UIWidgetCueWords:UpdateText()
    DataModel.nTextFadeIn = DataModel.nTextFadeIn + 1
    local tTable = DataModel.tText[DataModel.nTextFadeIn]
    if not tTable then
        return
    end
    DataModel.nTextNextTime = tTable.nInterval
    if tTable then
        self:AppendAText(tTable, DataModel.nTextFadeIn)
    end
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIWidgetCueWords:AppendAText(tTable, i)
    local szText = tTable.szText
    local nFont = tTable.nFont
    local szString = UIHelper.AttachTextColor(UIHelper.GBKToUTF8(szText), UIDialogueColorTab[nFont] and nFont or FontColorID.Text_Level1) --默认#d7f6ff
    -- local szString = UIDialogueColorTab[nFont] and UIHelper.AttachTextColor(UIHelper.GBKToUTF8(szText), nFont) or szText

    UIHelper.AddPrefab(self.CellPrefabID, self.LayoutContent, szString)
    
    -- if DataModel.bTextRight then
    --     local nX = hList.nX or hList:GetW()
    --     local nCount = hList:GetItemCount()
    --     local hText = hList:Lookup(nCount - 1)
    --     hText:SetRelX(nX)
    --     nX = nX - hText:GetW() - 10
    --     hList.nX = nX
    -- end
end

function UIWidgetCueWords:UpdateFade()
    if DataModel.nFadeInTime and DataModel.nFadeInTime > 0 then
        DataModel.nFadeInTime = DataModel.nFadeInTime - 1
        self:SetAlpha()
    elseif DataModel.nKeepTime and DataModel.nKeepTime > 0 then
        if DataModel.nKeepTime == DataModel.nKeepTimeOrg then
            self:SetShowText()
        end

        DataModel.nKeepTime = DataModel.nKeepTime - 1
        self:SetAlpha()
    elseif DataModel.nFadeOutTime and DataModel.nFadeOutTime > 0 then
        DataModel.nFadeOutTime = DataModel.nFadeOutTime - 1
        self:SetAlpha()
    else
        self:Close()
    end

    if DataModel.nTextNextTime and DataModel.nTextNextTime > 0 then
        DataModel.nTextNextTime = DataModel.nTextNextTime - 1
        if  DataModel.nTextNextTime == 0 then
            self:UpdateText()
        end
    end
end

function UIWidgetCueWords:SetAlpha()
	local nAlpha = 0
	if DataModel.nFadeInTime and DataModel.nFadeInTime > 0 then
		nAlpha = (DataModel.nFadeInTimeOrg - DataModel.nFadeInTime) * DataModel.fFadeInScale
		if nAlpha >= ALPHA_MAX then
			DataModel.nFadeOutTime = 0
			nAlpha = ALPHA_MAX
		end
	elseif DataModel.nKeepTime and DataModel.nKeepTime > 0 then
		nAlpha = ALPHA_MAX
	elseif DataModel.nFadeOutTime and DataModel.nFadeOutTime > 0 then
		nAlpha = DataModel.nFadeOutTime * DataModel.fFadeOutScale
		if nAlpha >= ALPHA_MAX then
			DataModel.nFadeOutTime = DataModel.nFadeOutTime - ((nAlpha - ALPHA_MAX) / DataModel.fFadeOutScale)
			nAlpha = ALPHA_MAX
		end
	end
    UIHelper.SetOpacity(self._rootNode, nAlpha)
end

return UIWidgetCueWords