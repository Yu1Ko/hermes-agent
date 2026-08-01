-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelToyJingBianTuView
-- Date: 2024-11-21 14:21:35
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MIN_SCALE = 0.53
local PAGE_TYPE = {
    LAODUCHA = 1,
    GUANYIN = 2,
}
local IMG_TITLE = {
    [PAGE_TYPE.LAODUCHA] = "UIAtlas2_JingBianTu_JingBianTu_Img_Title_Lao.png",
    [PAGE_TYPE.GUANYIN] = "UIAtlas2_JingBianTu_JingBianTu_Img_Title_GuanYin.png",
}
local UIPanelToyJingBianTuView = class("UIPanelToyJingBianTuView")

function UIPanelToyJingBianTuView:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(nType)
    self:UpdateInfo()
end

function UIPanelToyJingBianTuView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelToyJingBianTuView:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnNone, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if not self:CanScale() then return end
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)

    UIHelper.BindUIEvent(self.BtnContent, EventType.OnTouchBegan, function(btn, nX, nY)
        if not self:CanMove() then return end
        self.TouchComponent:TouchBegin(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnContent, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self:CanMove() then return end
        self.TouchComponent:TouchMoved(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnReaded, EventType.OnClick, function(btn, nX, nY)
        self:ShowInfoDetail(false)
        self:ShowAllTitle(true)
    end)

    UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function(btn, nX, nY)
        self.TouchComponent:Scale(self.nDefaultScale)
        self.TouchComponent:SetPosition(0, 0)
        self:ShowBtnReturn(false)
        self:ShowInfoDetail(false)
        self:ShowAllTitle(true)
    end)
end

function UIPanelToyJingBianTuView:RegEvent()
    

end

function UIPanelToyJingBianTuView:UnRegEvent()
    
end


function UIPanelToyJingBianTuView:Init(nType)
    self:SetCanScale(true)
    self:SetCanMove(true)
    self:SetType(nType)
    self:InitTouchComponent()
end


function UIPanelToyJingBianTuView:InitTouchComponent()
    
    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent:Init(self.WidgetImgParent)

    self.TouchComponent:SetScaleLimit(MIN_SCALE, self.nMaxScale)
    self.TouchComponent:SetRangeWidget(self.WidgetMapMask)
    self.TouchComponent:RegisterPosEvent(function(x, y)
        local nScale = self.TouchComponent:GetScale()
        local nImgWorldX, nImgWorldY = UIHelper.GetWorldPosition(self.WidgetImgParent)
        for nIndex, button in ipairs(self.tbTitleList) do
            local pos = self.tbTitlePos[nIndex]
            local nWorldX, nWorldY = pos.nX * nScale * 2 + nImgWorldX, pos.nY * nScale * 2 + nImgWorldY
            UIHelper.SetWorldPosition(button, nWorldX, nWorldY)
        end
    end)
    self.TouchComponent:Scale(self.nDefaultScale)
    self.TouchComponent:SetPosition(0, 0)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelToyJingBianTuView:UpdateInfo()

    for nIndex, parent in ipairs(self.tbTitleList) do
        local tbInfo = self.tbInfoList[nIndex]
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetJingBianTuTitle, parent, tbInfo)
    end
    UIHelper.SetSpriteFrame(self.ImgTitle, IMG_TITLE[self.nType])
end


function UIPanelToyJingBianTuView:UpdateTitleInfoList(nType)
    local tbLine = g_tTable.MoGaoKuInfo:Search(nType)
    local szButtonList = tbLine.szButtonList
    local tbButtonList = string.split(szButtonList, ";")
    self.tbInfoList = {}
    for nIndex, szButtonID in ipairs(tbButtonList) do
        local tbButtonInfo = g_tTable.MoGaoKuButton:Search(tonumber(szButtonID))
        table.insert(self.tbInfoList, tbButtonInfo)
    end
    self.nMaxScale = tbLine.fMaxScale
    self.nDefaultScale = tbLine.fDefaultScale
end

function UIPanelToyJingBianTuView:SetCurTitleInfo(button, tbInfo)
    self.TouchComponent:Scale(tbInfo.fTargetScale)
    self.TouchComponent:MoveToNode(button)
    self:ShowAllTitle(false)
    self:ShowInfoDetail(true, tbInfo)
    self:ShowBtnReturn(true)
end

function UIPanelToyJingBianTuView:SetType(nType)
    self.nType = nType
    self.tbTitleList = self.nType == PAGE_TYPE.LAODUCHA and self.tbDuChaTitleList or self.tbGuanYinTitleList
    self.WidgetImgParent = self.nType == PAGE_TYPE.GUANYIN and self.WidgetImgContentGY or self.WidgetImgContent
    self.WidgetTitleParent = self.nType == PAGE_TYPE.GUANYIN and self.WidgetTitleGuanYin or self.WidgetTitleLaoDuCha
    self.tbTitlePos = {}
    self:UpdateTitleInfoList(nType)
    local nImgWorldX, nImgWorldY = UIHelper.GetWorldPosition(self.WidgetImgParent)
    for nIndex, button in ipairs(self.tbTitleList) do
        UIHelper.SetSwallowTouches(button, false)
        UIHelper.BindUIEvent(button, EventType.OnClick, function(btn)
            --选中当前按钮
            self:SetCurTitleInfo(button, self.tbInfoList[nIndex])
        end)
        local nWorldX, nWorldY =  UIHelper.GetWorldPosition(button)
        table.insert(self.tbTitlePos, {nX = nWorldX - nImgWorldX, nY = nWorldY - nImgWorldY})
    end

    UIHelper.SetVisible(self.WidgetImgContentGY, self.nType ~= PAGE_TYPE.LAODUCHA)
    UIHelper.SetVisible(self.WidgetImgContent, self.nType == PAGE_TYPE.LAODUCHA)
    UIHelper.SetVisible(self.WidgetTitleGuanYin, self.nType ~= PAGE_TYPE.LAODUCHA)
    UIHelper.SetVisible(self.WidgetTitleLaoDuCha, self.nType == PAGE_TYPE.LAODUCHA)
end

local function _getParseDetailText(szContent)
    local szText = UIHelper.GBKToUTF8(szContent)
    szText = string.gsub(szText, "\t", "      ")
    szText = string.pure_text(szText)
    return szText
end

function UIPanelToyJingBianTuView:ShowInfoDetail(bShow, tbInfo)
    UIHelper.SetVisible(self.WidgetLabelContent, bShow)
    if bShow then
        UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tbInfo.szName))
        UIHelper.SetString(self.LabelContent1, _getParseDetailText(tbInfo.szContent))
    end
    self:SetCanScale(not bShow)
    self:SetCanMove(not bShow)
end

function UIPanelToyJingBianTuView:ShowBtnReturn(bShow)
    UIHelper.SetVisible(self.BtnReturn, bShow)
end

function UIPanelToyJingBianTuView:ShowAllTitle(bShow)
    for nIndex, button in ipairs(self.tbTitleList) do
        UIHelper.SetVisible(button, bShow)
    end
end

function UIPanelToyJingBianTuView:SetCanScale(bCanScale)
    self.bCanScale = bCanScale
end

function UIPanelToyJingBianTuView:SetCanMove(bCanMove)
    self.bCanMove = bCanMove
end

function UIPanelToyJingBianTuView:CanScale()
    return self.bCanScale
end

function UIPanelToyJingBianTuView:CanMove()
    return self.bCanMove
end


return UIPanelToyJingBianTuView