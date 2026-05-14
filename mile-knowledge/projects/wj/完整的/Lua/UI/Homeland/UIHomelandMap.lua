-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMap
-- Date: 2023-03-27 20:35:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMap = class("UIHomelandMap")

function UIHomelandMap:OnEnter(nMapID, nCopyIndex, nLandIndex, dwSkinID, tbCommunityInfo)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.nLandIndex = nLandIndex
    self.dwSkinID = dwSkinID
    self.tbCommunityInfo = tbCommunityInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)
end

function UIHomelandMap:OnExit()
    self.bInit = false

    UITouchHelper.UnBindUIZoom()
end

function UIHomelandMap:BindUIEvent()
    for index, tog in ipairs(self.tbTogHome or {}) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupHome, tog)
        -- UIHelper.SetSwallowTouches(tog, false)
        UIHelper.SetTouchDownHideTips(tog, false)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.TouchComponent:MoveToNode(tog)
            Event.Dispatch(EventType.OnSelectHomelandMyHomeArea, index)
        end)

        UIHelper.SetSelected(tog, false)
    end

    UIHelper.SetTouchDownHideTips(self.BtnMap, false)
    UIHelper.SetSwallowTouches(self.BtnMap, false)
    UIHelper.BindUIEvent(self.BtnMap, EventType.OnTouchBegan, function(btn, nX, nY)
        self.TouchComponent:TouchBegin(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnMap, EventType.OnTouchMoved, function(btn, nX, nY)
        self.TouchComponent:TouchMoved(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnMap, EventType.OnClick, function()
        for index, tog in ipairs(self.tbTogHome or {}) do
            UIHelper.SetSelected(tog, false)
        end
    end)

    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent:Init(self.WidgetMap)
    self.TouchComponent:SetScaleLimit(0.6, 1)
    self.TouchComponent:SetPosition(0, 0)
    self.TouchComponent:Scale(0.6)
end

function UIHomelandMap:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        for index, tog in ipairs(self.tbTogHome or {}) do
            UIHelper.SetSelected(tog, false)
        end
    end)
end

function UIHomelandMap:UpdateInfo()
    for nIndex, tog in ipairs(self.tbTogHome or {}) do
        local tbChilds = UIHelper.GetChildren(tog) or {}
        local WidgetHomeLandMapModel = tbChilds[1]
        if WidgetHomeLandMapModel then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeLandMapModelCell, WidgetHomeLandMapModel)
            local tbInfo = self.tbCommunityInfo.tLandInfo[nIndex]
            script:OnEnter(nIndex, tbInfo)
        end
        if nIndex == self.nLandIndex then
            UIHelper.SetSelected(tog, true)
            self.TouchComponent:MoveToNode(tog)
            Event.Dispatch(EventType.OnSelectHomelandMyHomeArea, nIndex)
        end
    end
end


return UIHomelandMap