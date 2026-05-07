-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentMainView
-- Date: 2025-07-08 10:02:47
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbTone2Name = {
    [1] = "高",
    [2] = "中",
    [3] = "低",
    [4] = "倍低",
}

local UIInstrumentMainView = class("UIInstrumentMainView")

function UIInstrumentMainView:OnEnter(szType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szType = szType
    self:Init()
    self:UpdateInfo()

    UIHelper.SetSelected(self.TogFreedom, true)
    UIHelper.SetSelected(self.TogPresets, false)
    InstrumentData.CheckShowRuleTip()
end

function UIInstrumentMainView:OnExit()
    InputHelper.LockMove(false)
    UIHelper.ShowInteract()
    UIMgr.ShowView(VIEW_ID.PanelMainCity)
    ShortcutInteractionData.SetEnableKeyBoard(true)

    InstrumentData.UnInit()
    MusicCodeData.UnInit()

    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentMainView:BindUIEvent()
    UIHelper.SetToggleGroupIndex(self.TogFreedom, ToggleGroupIndex.InstrumentMode)
    UIHelper.SetToggleGroupIndex(self.TogPresets, ToggleGroupIndex.InstrumentMode)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIHelper.ShowConfirm(g_tStrings.STR_INSTRUMENT_QUIT_CONFIRM, function ()
            UIMgr.Close(self)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelMusicRulePop)
    end)

    UIHelper.BindUIEvent(self.TogFreedom, EventType.OnSelectChanged, function(_, bSelected)
        if not self.scritpPlayer or not bSelected then
            return
        end

        self.scritpPlayer:SetFreeMode(true)
    end)

    UIHelper.BindUIEvent(self.TogPresets, EventType.OnSelectChanged, function(_, bSelected)
        if not self.scritpPlayer or not bSelected then
            return
        end

        self.scritpPlayer:SetFreeMode(false)
    end)
end

function UIInstrumentMainView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 5, function()
            UIHelper.LayoutDoLayout(self.LayoutWidgetMusicBtnList)
        end)
    end)

    Event.Reg(self, EventType.OnSelectInstrumentMusic, function (tData, bPreset)
        if not bPreset then
            UIHelper.SetSelected(self.TogPresets, false, false)
            UIHelper.SetSelected(self.TogFreedom, true, false)
        end
    end)
end

function UIInstrumentMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIInstrumentMainView:Init()
    InputHelper.LockMove(true)
    UIMgr.HideView(VIEW_ID.PanelMainCity)
    UIHelper.HideInteract()
    MusicCodeData.Init()
    MusicCodeData.LoginAccount()
    self:InitInput()

    local szBgPath = "UIAtlas2_Music_Music1_bg_"..self.szType
    UIHelper.SetSpriteFrame(self.ImgBg, szBgPath)

    local szTitle = Table_GetInstrumentName(self.szType)
    if szTitle and szTitle ~= "" then
        szTitle = UIHelper.GBKToUTF8(szTitle)
        UIHelper.SetString(self.LabelTitle, szTitle)
    end
end

function UIInstrumentMainView:InitInput()
    ShortcutInteractionData.SetEnableKeyBoard(false)
    InstrumentData.Init(self.szType)

    if not self.scritpMenu then
        self.scritpMenu = UIHelper.AddPrefab(PREFAB_ID.WidgetMusicMenu, self.WidgetMusicMenu)
        self.scritpMenu:OnEnter(InstrumentData)
    end

    if not self.scritpPlayer then
        self.scritpPlayer = UIHelper.AddPrefab(PREFAB_ID.WidgetMusicMiddleTip, self.WidgetMusicMiddleTip)
        self.scritpPlayer:OnEnter(InstrumentData)
    end

    if not self.scritpPerset then
        self.scritpPerset = UIHelper.AddPrefab(PREFAB_ID.WidgetPresetMusicTip, self.WidgetPresetMusicTip)
        self.scritpPerset:OnEnter(InstrumentData)
    end
end

function UIInstrumentMainView:UpdateInfo()
    self:UpdateKeyList()
end

function UIInstrumentMainView:UpdateKeyList()
    local tbKeys = InstrumentData.GetKeyList()
    if not tbKeys then
        return
    end

    for nTone, tLine in ipairs(tbKeys) do
        if not table.is_empty(tLine) then
            local scriptLine = UIHelper.AddPrefab(PREFAB_ID.WidgetMusicBtnList, self.LayoutWidgetMusicBtnList)
            UIHelper.SetString(scriptLine.LabelMusicTitle, tbTone2Name[nTone])
            for nIndex, tbKey in pairs(tLine) do
                local szKey = tbKey.szKey
                local szKeyName = UIHelper.NumberToChinese(nIndex, true)
                local widget = scriptLine.tbWidgetKeys[nIndex]
                local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMusicBtn, widget)
                scriptCell:OnEnter(nTone, nIndex, szKeyName, szKey)
                InstrumentData.BindBtnEvent(false, scriptCell.BtnKey, scriptCell.ImgBtnBg_Up, szKey, function (bTouch)
                    UIHelper.SetVisible(scriptCell.ImgBtnBg_Up, bTouch)
                end)
            end
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutWidgetMusicBtnList, true, true)
    self:AdjustBgPosition()
end

function UIInstrumentMainView:AdjustBgPosition()
    local nPosX_Bg, nPosY_Bg = UIHelper.GetWorldPosition(self.ImgBg)
    local nPosX_List, nPosY_List = UIHelper.GetWorldPosition(self.LayoutWidgetMusicBtnList)
    local nSizeX_List, nSizeY_List = UIHelper.GetContentSize(self.LayoutWidgetMusicBtnList)
    local nCenterY = nPosY_List + nSizeY_List / 2

    UIHelper.SetWorldPosition(self.ImgBg, nPosX_Bg, nCenterY)
end


return UIInstrumentMainView