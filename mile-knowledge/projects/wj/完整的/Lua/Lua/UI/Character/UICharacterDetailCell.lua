-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterDetailCell
-- Date: 2022-11-10 10:56:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterDetailCell = class("UICharacterDetailCell")

function UICharacterDetailCell:OnEnter(player, nIndex, nSubIndex, tbInfo)
    self.player = player
    self.nIndex = nIndex
    self.nSubIndex = nSubIndex
    self.tbInfo = tbInfo

    self.szKey = table.get_key(g_tStrings.PLAYER_ATTRIB_NAME, self.tbInfo.szName)
    self.tbShowConfig = PlayerData.GetAttribShowConfig(self.player)


    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICharacterDetailCell:OnExit()
    self.bInit = false
end

function UICharacterDetailCell:BindUIEvent()
    UIHelper.BindUIEvent(self.Toggle, EventType.OnClick, function ()
        local bSelected = UIHelper.GetSelected(self.Toggle)
        Event.Dispatch(EventType.OnChangeCharacterAttribShowConfig, self.szKey, bSelected)
    end)

    UIHelper.BindUIEvent(self.TogDetail, EventType.OnClick,function ()
        local bSelected = UIHelper.GetSelected(self.TogDetail)
        self:ShowDetail(bSelected)

        if self.nTouchEnabledTimerID then
            Timer.DelTimer(self, self.nTouchEnabledTimerID)
            self.nTouchEnabledTimerID = nil
        end
        UIHelper.SetTouchEnabled(self.TogDetail, false)
        self.nTouchEnabledTimerID = Timer.Add(self, 0.2, function ()
            UIHelper.SetTouchEnabled(self.TogDetail, true)
        end)
    end)

    -- UIHelper.SetSwallowTouches(self.Toggle, false)
    UIHelper.SetSwallowTouches(self.TogDetail, false)
end

function UICharacterDetailCell:RegEvent()
    -- Event.Reg(self, EventType.OnSelectedMoreDetailTog1, function (nIndex)
    --     if self.nIndex ~= nIndex then
    --         UIHelper.SetSelected(self.TogDetail, false)
    --         UIHelper.LayoutDoLayout(self.WidgetCharacterDetailCell)
    --     end
    -- end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 2, function ()
            UIHelper.WidgetFoceDoAlign(self)
            UIHelper.LayoutDoLayout(self.LayoutDetail)
            UIHelper.LayoutDoLayout(self.WidgetCharacterDetailCell)
        end)
    end)
end

function UICharacterDetailCell:UpdateInfo()
    UIHelper.SetVisible(self.ImgBG, self.nSubIndex % 2 == 1)
    UIHelper.SetString(self.LabelName, self.tbInfo.szName)
    UIHelper.SetString(self.LabelNameUp, self.tbInfo.szName)
    UIHelper.SetString(self.LabelValue, self.tbInfo.szValue)
    UIHelper.SetString(self.LabelValueUp, self.tbInfo.szValue)
    UIHelper.SetRichText(self.RichTextDetail, string.format("<color=#AED6E0>%s</c>", self.tbInfo.szTip))
    if self.tbShowConfig[self.szKey] then
        UIHelper.SetSelected(self.Toggle, true)
        UIHelper.SetSelected(self.TogDetail, true)
        self:ShowDetail(true)
    else
        UIHelper.SetSelected(self.Toggle, false)
        self:ShowDetail(false)
    end
end

function UICharacterDetailCell:ShowDetail(bShow)
    if bShow then
        UIHelper.SetVisible(self.LayoutDetail, true)
        UIHelper.LayoutDoLayout(self.LayoutDetail)
        UIHelper.LayoutDoLayout(self.WidgetCharacterDetailCell)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
        Event.Dispatch(EventType.OnSelectedMoreDetailTog1, self.nIndex)
        Event.Dispatch(EventType.OnSelectedMoreDetailTog2, self)
    else
        UIHelper.LayoutDoLayout(self.WidgetCharacterDetailCell)
        Event.Dispatch(EventType.OnSelectedMoreDetailTog2, self)
    end
end

return UICharacterDetailCell