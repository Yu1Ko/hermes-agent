local UIWorldCityIcon = class("UIWorldCityIcon")

function UIWorldCityIcon:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnCity, EventType.OnClick, function()
        if self.fnClick then
            self.fnClick(self.szName)
        end
        -- Event.Dispatch("ON_MAP_OPEN_PERIPHERA", self.szName)
    end)

    Event.Reg(self, "ON_WORLD_MAP_CITY_SELECT", function(obj, bEnable)
        if not bEnable or (bEnable and obj ~= self) then
            self:Select(false)
        end
    end)

    Event.Reg(self, "ON_WORLD_MAP_CITY_HIGHLIGHT", function(obj, bEnable)
        if not bEnable or (bEnable and obj ~= self) then
            self:Highlight(false)
        end
    end)

    Event.Reg(self, "ON_WORLD_MAP_CITY_LOCATE", function(obj, bEnable)
        if not bEnable or (bEnable and obj ~= self) then
            self:Locate(false)
        end
    end)

    Event.Reg(self, 'ON_WORLD_MAP_SCALE', function(nScale)
        UIHelper.SetScale(self.ImgConditionBg, 1 / nScale, 1 / nScale)
        UIHelper.SetScale(self.WidgetTeammate, 1 / nScale, 1 / nScale)
        UIHelper.SetScale(self.WidgetLocation, 1 / nScale, 1 / nScale)
        -- self:UpdateCityNamePosition()
    end)
end

function UIWorldCityIcon:OnEnter(szName, tbInfo)
    self:RegisterEvent()
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)

    self:UpdateInfo(szName, tbInfo)
end

function UIWorldCityIcon:UpdateCityNamePosition()
    local x, _ = 0, 0
    local sizeName = self.labelName:getContentSize()

    if safe_check(self.ImgConditionBg) then
        x, _ = self.ImgConditionBg:getPosition()
        self.ImgConditionBg:setPosition(x, sizeName.height)
    end

    local sizeBg = self.ImgNameBg:getContentSize()
    sizeBg.height = sizeName.height + 32
    self.ImgNameBg:setContentSize(sizeBg)
end

function UIWorldCityIcon:UpdateInfo(szName, tbInfo)
    self.szName = szName
    self.tbInfo = tbInfo

    self.labelName:setString(tbInfo.szName)
    self.ImgSelect:setVisible(false)
    self.ImgTrace:setVisible(false)

    -- self:UpdateCityNamePosition()

    UIHelper.SetSpriteFrame(self.ImgCityIcon, tbInfo.szFrame)
    UIHelper.SetSpriteFrame(self.ImgCondition, tbInfo.szCampFrame)
    UIHelper.SetContentSize(self.ImgCityIcon, tbInfo.nSize, tbInfo.nSize)
end

function UIWorldCityIcon:Highlight(bEnable)
    if self.bHighlight == bEnable then
        return
    end
    UIHelper.SetVisible(self.ImgTrace, bEnable)
    if bEnable then
        Event.Dispatch("ON_WORLD_MAP_CITY_HIGHLIGHT", self, bEnable)
    end
    self.bHighlight = bEnable
end

function UIWorldCityIcon:Locate(bEnable)
    if self.bLocation == bEnable then
        return
    end

    UIHelper.SetVisible(self.WidgetLocation, bEnable)
    local script = UIHelper.GetBindScript(self.WidgetLocation)
    if script then
        script:Enable(bEnable)
    end

    if bEnable then
        Event.Dispatch("ON_WORLD_MAP_CITY_LOCATE", self, bEnable)
    end

    self.bLocation = bEnable
end

function UIWorldCityIcon:Select(bEnable)
    if self.bSelect == bEnable then
        return
    end
    UIHelper.SetVisible(self.ImgSelect, bEnable)
    if bEnable then
        Event.Dispatch("ON_WORLD_MAP_CITY_SELECT", self, bEnable)
    end
    self.bSelect = bEnable
end

function UIWorldCityIcon:SetTeammate(bEnable)
    UIHelper.SetVisible(self.WidgetTeammate, bEnable)
end

return UIWorldCityIcon