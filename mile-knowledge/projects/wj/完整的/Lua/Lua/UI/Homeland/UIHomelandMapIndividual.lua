-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMapIndividual
-- Date: 2023-03-27 20:35:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMapIndividual = class("UIHomelandMapIndividual")

function UIHomelandMapIndividual:OnEnter(nMapID, nCopyIndex, nLandIndex, dwSkinID)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.nLandIndex = nLandIndex
    self.dwSkinID = dwSkinID

    -- package.loaded["Lua/Tab/UIPrivateHomeSkinTab.lua"] = nil
    -- require("Lua/Tab/UIPrivateHomeSkinTab.lua")

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local pHLMgr = GetHomelandMgr()
    if pHLMgr then
        pHLMgr.ApplyHLLandInfo(self.nLandIndex)
    end

    self:UpdateInfo()

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)
end

function UIHomelandMapIndividual:OnExit()
    self.bInit = false
    self:SetAllTextureAntiAliasEnabled(true)
    UITouchHelper.UnBindUIZoom()
end

function UIHomelandMapIndividual:BindUIEvent()
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
    self:FitMapToScreen()
end

function UIHomelandMapIndividual:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
        local nRetCode = arg0
        if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO or nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then  --申请某块地详情
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			if self.nMapID == dwMapID and self.nCopyIndex == nCopyIndex and self.nLandIndex == nLandIndex then
				self:UpdateInfo()
			end
		end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:FitMapToScreen()
    end)
end

function UIHomelandMapIndividual:UpdateInfo()
    local bNotOwn = true
    local uUnlockSubLand = 0
    local uDemolishSubLand = 0

    local tbLandInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
    if tbLandInfo then
        uUnlockSubLand = tbLandInfo.uUnlockSubLand or 0
        uDemolishSubLand = tbLandInfo.uDemolishSubLand or 0
    end

    local tbPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(self.nMapID, self.nCopyIndex)
    if tbPrivateInfo then
        bNotOwn = false
    end

	local tbSkinUIInfo = Table_GetPrivateHomeSkinList(self.nMapID)
    if not tbSkinUIInfo then
        LOG.ERROR("UIHomelandMapIndividual:UpdateInfo() get tbSkinUIInfo error! nMapID:"..tostring(self.nMapID))
        return
    end

    local tbCurSkinUIInfo = tbSkinUIInfo[self.dwSkinID + 1]
    if not tbCurSkinUIInfo then
        LOG.ERROR("UIHomelandMapIndividual:UpdateInfo() get tbCurSkinUIInfo error! dwSkinID:"..tostring(self.dwSkinID))
        return
    end

    for i, img in ipairs(self.tbImgAreaState) do
        local bNotDemolish = not kmath.is_bit1(uDemolishSubLand, i)
        local bLocked = not kmath.is_bit1(uUnlockSubLand, i)

        if bNotOwn or bLocked then
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Home_HomeLand_HomeIcon_icon_lock.png")
        elseif bNotDemolish then
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Home_HomeLand_HomeIcon_icon_eradicate.png")
        else
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Home_HomeLand_HomeIcon_icon_nuild.png")
        end
    end

    for i, img in ipairs(self.tbImgSeparateMap) do
        UIHelper.SetTexture(img, string.format("Texture/HomeLandMap/IndividualMap/%s/%s%d.png", tbCurSkinUIInfo.szImgName, tbCurSkinUIInfo.szImgName, i))
    end

    for i, img in ipairs(self.tbImgAreaMap) do
        local tbConfig = TabHelper.GetUIPrivateHomeSkinTab(self.nMapID, self.dwSkinID, i)
        if tbConfig then
            UIHelper.SetPosition(img, tbConfig.nX, tbConfig.nY)
            UIHelper.SetContentSize(img, tbConfig.nWidth, tbConfig.nHeight)
        end

        local bNotDemolish = not kmath.is_bit1(uDemolishSubLand, i)
        UIHelper.SetTexture(img, string.format("Texture/HomeLandMap/IndividualMap/%s/%d.png", tbCurSkinUIInfo.szImgName, i), true, function ()
            local tex = UIHelper.GetTexture(img)
            if tex then
                UIHelper.SetTextureAntiAliasEnabled(tex, false)end
        end)
        local tex = UIHelper.GetTexture(img)
        if tex then
            UIHelper.SetTextureAntiAliasEnabled(tex, false)
        end
        UIHelper.SetVisible(img, bNotDemolish)
    end
end

function UIHomelandMapIndividual:FitMapToScreen()
    if not self.TouchComponent then
        return
    end

    local tScreenSize = UIHelper.GetCurResolutionSize()--UIHelper.GetWinSizeInPixels()--UIHelper.GetCurResolutionSize()--UIHelper.DeviceScreenSize()
    local nScreenWidth, nScreenHeight = tScreenSize.width, tScreenSize.height

    local nMapW, nMapH = UIHelper.GetContentSize(self.WidgetMap)
    if nMapW == 0 or nMapH == 0 then
        return
    end

    local nScaleMin = math.max(nScreenWidth / nMapW, nScreenHeight / nMapH)
    local nScaleMax = nScaleMin * 2.5 / 0.6

    self.TouchComponent:SetScaleLimit(nScaleMin, nScaleMax)
    self.TouchComponent:Scale(nScaleMin)
    self.TouchComponent:SetPosition(0, 0)
end

function UIHomelandMapIndividual:SetAllTextureAntiAliasEnabled(bEnabled)
    for i, img in ipairs(self.tbImgAreaMap) do
        local tex = UIHelper.GetTexture(img)
        if tex then
            UIHelper.SetTextureAntiAliasEnabled(tex, bEnabled)
        end
    end
end

return UIHomelandMapIndividual