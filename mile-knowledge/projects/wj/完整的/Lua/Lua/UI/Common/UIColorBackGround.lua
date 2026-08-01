-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIColorBackGround
-- Date: 2022-11-21 20:07:35
-- Desc: ?
-- ---------------------------------------------------------------------------------


local tbIgnoreDevices =
{
    ["HUAWEI ELS-AN00"] = true, -- HUAWEI P40 Pro 5G 全网通版
    ["HUAWEI ELS-TN00"] = true, -- HUAWEI P40 Pro 5G 移动版
    ["HUAWEI FGD-AL00"] = true, -- 华为畅享 70
    ["samsung SM-G9600"] = true, -- 三星 S9
}

local UIColorBackGround = class("UIColorBackGround")

function UIColorBackGround:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self._donotdestroy = true
    self._keepmt = true
    if self._widgetMgr.setClearAdaptWhenCleanup then
        self._widgetMgr:setClearAdaptWhenCleanup(false)
    end
end

function UIColorBackGround:OnExit()
    --self.bInit = false
end

function UIColorBackGround:OnDestroy()

end

function UIColorBackGround:Init()
    self.nParentViewID = nil
    self.curParent = nil
    self.tbColorBgParent = {}
    self.tbParentToTextureMap = {}
    self.tbTextureHasBlured = {}

    self.bBlurEnable = Const.UIBgBlur.bEnable
    self.nBlurRadius = Const.UIBgBlur.nRadius
    self.nBlurSampleNum = Const.UIBgBlur.nSampleNum
end

function UIColorBackGround:PlayHideAnim()
    UIHelper.PlayAni(self, self._rootNode, "AniBackGroundHide")
end

function UIColorBackGround:AddToParent(parent, nParentViewID, bIsReplace, pRetTexture)
    if not safe_check(parent) then
        return
    end

    self.nParentViewID = nParentViewID

    if not bIsReplace then
        self:_setVisible(self.SpriteBlur, false, true)
        self:_setVisible(self.SpriteAlpha, false, true)
        self:_setVisible(self.AnimNode, false, true)
    end

	self:_addToParent(parent, pRetTexture)

	table.insert(self.tbColorBgParent, parent)
end

function UIColorBackGround:RemoveFromParent(parent)
    if not safe_check(parent) then
        --LOG.ERROR("UIColorBackGround:RemoveFromParent, parent is null.")
		return
	end

    local nIdxDel = nil
    for k, v in ipairs(self.tbColorBgParent) do
        if v == parent then
            nIdxDel = k
            break
        end
    end

    if nIdxDel then
        local removeParent = table.remove(self.tbColorBgParent, nIdxDel)
        local removeTexture = self.tbParentToTextureMap[removeParent]
        if safe_check(removeTexture) then
            if removeTexture == self.pFirstTexture then
                self.pFirstTexture = nil
            end

            removeTexture:release()
            self.tbParentToTextureMap[removeParent] = nil
            self.tbTextureHasBlured[removeTexture] = nil
        else
        --    LOG.ERROR("UIColorBackGround:RemoveFromParent, removeTexture is null.")
        end

        if removeParent == self.curParent then
            self.curParent = nil
        end
    end

	local prevParent = self.tbColorBgParent[#self.tbColorBgParent]
	if safe_check(prevParent) then
		local prevParentScript = UIHelper.GetBindScript(prevParent)
		local nParentViewID = prevParentScript and prevParentScript._nViewID or 0

		self.nParentViewID = nParentViewID

		self:_addToParent(prevParent)

		-- 将之前的截屏的贴图设置回去
		local pTexture = self.tbParentToTextureMap[prevParent]
        self:_updateBlur(pTexture)
        self:_updateAlpha()
        self:_updateAnim()
	else
        --LOG.ERROR("UIColorBackGround:RemoveFromParent, prevParent is null.")
        self:_setVisible(self.SpriteBlur, false)
        self:_setVisible(self.SpriteAlpha, false)

		UIHelper.SetVisible(self._rootNode, false)
		UIHelper.SetParent(self._rootNode, UIMgr.GetCurrentScene())

        UIHelper.SetSpriteFrame(self.SpriteBlur, "UIAtlas2_Public_PublicPanel_PublicPanel1_White.png")
	end
end

function UIColorBackGround:_addToParent(parent, pRetTexture)
    if not safe_check(parent) then
        return
    end

    UIHelper.SetParent(self._rootNode, parent)
    UIHelper.SetLocalZOrder(self._rootNode, -2)
    -- UIHelper.SetTag(self._rootNode, 100898)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetPosition(self._rootNode, 0, 0)

    self.curParent = parent

    if pRetTexture then
        self:_updateBlur(pRetTexture)
        self:_updateAlpha()
        self:_updateAnim()

        if safe_check(self.curParent) then
            if table.is_empty(self.tbParentToTextureMap) then
                self.pFirstTexture = pRetTexture
            end

            self.tbParentToTextureMap[self.curParent] = pRetTexture
        end
    end
end

function UIColorBackGround:_updateBlur(pTexture)
    local pBlurTex = (UIMgr.GetViewLayerByViewID(self.nParentViewID) == UILayer.Page) and self.pFirstTexture or pTexture
    if not safe_check(pBlurTex) then
        return
    end

    if self.tbTextureHasBlured[pBlurTex] then
        self:_setVisible(self.SpriteBlur, true)
        self:_setBlur(pBlurTex)
    else
        Timer.DelTimer(self, self.nUpdateBlurTimerID)
        self.nUpdateBlurTimerID = Timer.AddFrame(self, 1, function()
            self:_setVisible(self.SpriteBlur, true)
            self:_setBlur(pBlurTex)
        end)
    end
end

function UIColorBackGround:_updateAlpha()
    local bVisible = false
    local conf = TabHelper.GetUIViewTab(self.nParentViewID)
    if conf then
        local szLayerName = conf.szLayerName
        local nColorMaskAlpha = conf.nColorMaskAlpha
        if nColorMaskAlpha == 0 then
            bVisible = false
        elseif nColorMaskAlpha == 1 then
            bVisible = true
        else
            if (UILayer[szLayerName] == UILayer.Popup or UILayer[szLayerName] == UILayer.MessageBox or UILayer[szLayerName] == UILayer.SystemPop) then
                bVisible = true
            end
        end
    end
    self:_setVisible(self.SpriteAlpha, bVisible)
end

function UIColorBackGround:_updateAnim()
    local bVisible = false
    local conf = TabHelper.GetUIViewTab(self.nParentViewID)
    if conf and conf.bColorMaskAnim then
        local szLayerName = conf.szLayerName
        if UILayer[szLayerName] == UILayer.Page then
            bVisible = true
        end
    end

    self:_setVisible(self.AnimNode, bVisible)

    if bVisible then
        UIHelper.PlayAni(self, self._rootNode, "AniBackGroundShow")
    end
end

function UIColorBackGround:_setVisible(node, bVisible, bImmediately)
    --UIHelper.SetOpacity(node, bVisible and 255 or 0)
    UIHelper.SetVisible(node, bVisible)

    if bImmediately then
    --    node:visit()
    end
end

function UIColorBackGround:BindUIEvent()

end

function UIColorBackGround:RegEvent()
    --[[
    Event.Reg(self, EventType.OnCaptureNodeFinished, function(pRetTexture)
        self:_updateBlur(pRetTexture)
        self:_updateAlpha()
        self:_updateAnim()

        if safe_check(self.curParent) then
            if table.is_empty(self.tbParentToTextureMap) then
                self.pFirstTexture = pRetTexture
            end

            self.tbParentToTextureMap[self.curParent] = pRetTexture
        end
    end)
    ]]

    Event.Reg(self, EventType.OnSetScreenPortrait, function ()
        self.bSpriteBlurOffsetDirty = true
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function(nWidth, nHeight)
        UIHelper.WidgetFoceDoAlign(self)
    end)
end

function UIColorBackGround:_setBlur(pTexture)
    if not safe_check(pTexture) then
        return
    end

    if self.tbTextureHasBlured[pTexture] then
        Timer.DelTimer(self, self.nSetBlurTimerID)
        self.nSetBlurTimerID = Timer.AddFrame(self, 1, function()
            UIHelper.SetTextureWithBlurEx(self.SpriteBlur, pTexture, self.bBlurEnable, self.nBlurRadius, self.nBlurSampleNum)
        end)
    else
        UIHelper.SetTextureWithBlurEx(self.SpriteBlur, pTexture, self.bBlurEnable, self.nBlurRadius, self.nBlurSampleNum)
        self.tbTextureHasBlured[pTexture] = true
    end
end

function UIColorBackGround:UpdateInfo()

end

return UIColorBackGround