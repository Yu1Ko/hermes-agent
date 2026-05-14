-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIWidgetChuangYiBuff
-- Date: 2026-1-22 10:49:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetChuangYiBuff = class("CharacterHeadBuff")

function UIWidgetChuangYiBuff:OnEnter(tBuff)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    self.characterID = player.dwID
    self:UpdatePos()
    self:ShowChuangYiBuff(tBuff)
end

function UIWidgetChuangYiBuff:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetChuangYiBuff:BindUIEvent()

end

function UIWidgetChuangYiBuff:RegEvent()
    Event.Reg(self, "Move", function(name, x, y)
        local szRep = string.format("哈哈哈<img src='UIAtlas2_Public_PublicIcon_PublicIcon1_Down' width='%d' height='%d'/>\n", 25, 25)
        UIHelper.SetLabel(self.RichText, szRep)
    end)
    --Event.Dispatch("Move", "SFX",25,25)
end

function UIWidgetChuangYiBuff:UnRegEvent()

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetChuangYiBuff:UpdatePos()
    local screenSize = UIHelper.GetSafeAreaRect()
    local pw, ph = screenSize.width, screenSize.height
    local scaleX, scaley = UIHelper.GetScreenToResolutionScale()
    local width, height = UIHelper.GetContentSize(self._rootNode)

    scaleX = 1 / scaleX
    scaley = 1 / scaley
    local baseOffsetY = ph * 0.5 + height * 0.5
    local baseOffsetX = -pw * 0.5 - width * 0.5

    baseOffsetX = baseOffsetX + 50 -- 偏移量在此处修改
    baseOffsetY = baseOffsetY + 0 -- 偏移量在此处修改

    if self.nCycleTimeID then
        Timer.DelTimer(self, self.nCycleTimeID)
    end
    self.nCycleTimeID = Timer.AddFrameCycle(self, 1, function()
        local fnCallback = function(screenX, screenY)
            local contentScale = 1
            local scaleOffsetX = width * 0.5
            local scaleOffsetY = height * 0.5 * scaley
            local offsetX = baseOffsetX + (1 - contentScale) * scaleOffsetX
            local offsetY = baseOffsetY - (1 - contentScale) * scaleOffsetY
            local position = { x = screenX, y = screenY }

            UIHelper.SetPosition(self._rootNode, position.x * scaleX + offsetX, -position.y * scaley + offsetY)
        end

        local nX, nY = Scene_GetCharacterTopScreenPosX3D(self.characterID)
        fnCallback(nX, nY)
    end)

    Timer.Add(self, 2, function()
        if self.nCycleTimeID then
            Timer.DelTimer(self, self.nCycleTimeID)
            self.nCycleTimeID = nil -- 两秒后停止位置计算
        end
    end)
end

function UIWidgetChuangYiBuff:ShowChuangYiBuff(tBuff)
    if tBuff and tBuff.nLevel ~= self.nLevel and (not self.nEndFrame or tBuff.nEndFrame > self.nEndFrame) then
        self.nLevel = tBuff.nLevel
        self.nEndFrame = tBuff.nEndFrame

        UIHelper.PlayAni(self, self._rootNode, "AniWidgetMainCityChuangYiBuffShow", function()
            Timer.Add(self, 2, function()
                UIHelper.PlayAni(self, self._rootNode, "AniWidgetMainCityChuangYiBuffHide")
            end)
        end)
        UIHelper.PlaySFX(self.SFX, false)
        UIHelper.SetOpacity(self.WidgetChuangYiBuff, 255)
        UIHelper.SetOpacity(self.RichText, 255)
        local szDesc = GetBuffDesc(tBuff.dwID, tBuff.nLevel, "desc")
        szDesc = UIHelper.GBKToUTF8(szDesc)

        local split = string.split(szDesc, "，")
        local szRep = string.format("<img src='UIAtlas2_Public_PublicIcon_PublicIcon1_Down' width='%d' height='%d'/>\n", 25, 25)
        local szFinal = UIHelper.AttachTextColor(split[1], "ffffff") .. szRep
        szFinal = szFinal .. UIHelper.AttachTextColor(split[2], "ffffff") .. "<img src='UIAtlas2_Public_PublicIcon_PublicIcon1_up' width='25' height='25'/>"
        UIHelper.SetLabel(self.RichText, szFinal)
    end
end

return UIWidgetChuangYiBuff