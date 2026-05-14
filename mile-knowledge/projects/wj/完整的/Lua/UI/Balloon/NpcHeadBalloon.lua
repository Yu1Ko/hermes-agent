-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: NpcHeadBalloon
-- Date: 2022-12-26 10:49:31
-- Desc: ?
-- ---------------------------------------------------------------------------------
local BALLOON_VISIBLE_DISTANCE = 50 * 64
local NORMAL_SCALE_DISTANCE = 10 * 64
local NpcHeadBalloon = class("NpcHeadBalloon")
local DistancelScaleMin = 0.75
local MAX_CONTENT_LEN = 432
function NpcHeadBalloon:OnEnter(characterID, szContent, nChannel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.characterID = characterID
    self.szContent = szContent
    self.nChannel = nChannel
    self:UpdateInfo()
end

function NpcHeadBalloon:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function NpcHeadBalloon:BindUIEvent()

end

function NpcHeadBalloon:RegEvent()
    Event.Reg(self, EventType.SetNpcHeadBallonVisible, function(bVisible)
        UIHelper.SetOpacity(self._rootNode, bVisible and 255 or 0)
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function(width, height)
        self:UpdateInfo(true)
    end)
    Event.Reg(self, EventType.OnShowNpcHeadBalloon, function(characterID)
        -- 新的顶替旧的
        if self.characterID == characterID then
            Timer.DelAllTimer(self)
            self:RemoveNode()
        end
    end)
end

function NpcHeadBalloon:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function NpcHeadBalloon:UpdateInfo(bReUpdate)
    local player = GetClientPlayer()
    if not player then
        self:RemoveNode()
        return
    end
	local dwPlayerID = player.dwID
    if not bReUpdate then
        Timer.DelTimer(self, self.nTimeID)
    end
    Timer.DelTimer(self, self.nCycleTimeID)
    local nDistance = 0
    if self.characterID ~= dwPlayerID then
        nDistance = GetCharacterDistance(self.characterID, dwPlayerID)
        if nDistance > BALLOON_VISIBLE_DISTANCE or (not self:IsStoryChannel() and ((BALLOON_VISIBLE_DISTANCE - nDistance*2)/BALLOON_VISIBLE_DISTANCE < 0)) then
            LOG.INFO("NpcHeadBalloon,characterID = %d, nDistance = %d, too far, can not be show. szContent= %s", nDistance , self.characterID , self.szContent)
            self:RemoveNode()
            return
        end
	end
    local arrawW, arrawH = UIHelper.GetContentSize(self.ImgTogBg1)
    if not bReUpdate then
        local matchWidth = 0

        for name, value in string.gmatch(self.szContent, "(%w+)%s*=%s*\'([^\']*)\'") do
            if name == "width" then
                matchWidth = matchWidth + tonumber(value)
              
            end
        end
    
        local checkContent = string.gsub(self.szContent, "<img.-/>", "")
        if string.find(checkContent,"</href>") then
            checkContent = string.gsub(checkContent,"<[^>]+>", "")
        end
        self.CheckWidthLabel:setHorizontalAlignment(TextHAlignment.CENTER)
        self.CheckWidthLabel:enableWrap(false)
        self.CheckWidthLabel:setDimensions(0,0)
        self.CheckWidthLabel:setOverflow(LabelOverflow.NONE)
        UIHelper.SetString(self.CheckWidthLabel ,  checkContent)
        
        local labelW = UIHelper.GetWidth(self.CheckWidthLabel) + matchWidth
        if matchWidth == 0 then
            if labelW > MAX_CONTENT_LEN then
                self.CheckWidthLabel:setHorizontalAlignment(TextHAlignment.LEFT)
                self.CheckWidthLabel:setDimensions(MAX_CONTENT_LEN,0)
                self.CheckWidthLabel:setOverflow(LabelOverflow.RESIZE_HEIGHT)
                labelW = MAX_CONTENT_LEN
            end
        end
        labelW = (labelW < 100) and 100 or labelW
        if labelW > MAX_CONTENT_LEN then
            labelW = MAX_CONTENT_LEN
        end
        UIHelper.SetWidth(self.labelContent, labelW)
        UIHelper.SetWidth(self.ImgBubbleBg, UIHelper.GetWidth(self.labelContent) + 40)
        UIHelper.SetRichText(self.labelContent, self.szContent)
        UIHelper.SetRichTextCanClick(self.labelContent, false)
        UIHelper.SetPositionX(self.labelContent, 20)
        UIHelper.LayoutDoLayout(self.ImgBubbleBg)
        local layoutWidth, layoutHeight = UIHelper.GetContentSize(self.ImgBubbleBg)
        
       
        UIHelper.SetContentSize(self._rootNode, layoutWidth, layoutHeight)
        UIHelper.SetContentSize(self.AniNpcHecdBubble, layoutWidth, layoutHeight)
        
        UIHelper.SetPosition(self.ImgTogBg1, layoutWidth * 0.5, -arrawH)
        UIHelper.SetVisible(self._rootNode,true)
        local labelW, labelH = UIHelper.GetContentSize(self.labelContent)
        local nBalloonFadeTime = (labelW*labelH/3600 + 1) + 1.7
        self.nTimeID = Timer.Add(self , nBalloonFadeTime , function ()
            Timer.DelTimer(self, self.nTimeID)
            self:RemoveNode()
        end)
    end

    local parent = UIHelper.GetParent(self._rootNode)
    local pw, ph = UIHelper.GetContentSize(parent)
    local scaleX ,scaley= UIHelper.GetScreenToResolutionScale()
    local width, height = UIHelper.GetContentSize(self._rootNode)

    scaleX = 1/scaleX
    scaley = 1/scaley
    local baseOffsetY = ph * 0.5 + height * 0.5
    local baseOffsetX = -pw * 0.5 - width * 0.5

    baseOffsetX = baseOffsetX - arrawW * 0.5
    local labelW, labelH = UIHelper.GetContentSize(self.labelContent)
    baseOffsetY = baseOffsetY - arrawH * math.floor(labelH/UIHelper.GetFontSize(self.labelContent)) + 20
    -- if IsPlayer(self.characterID) then
    --     headOffsetX = 20
    --     headOffsetY = -20
    -- end

    local contentScale =  1
    if Platform.IsWindows() then
        contentScale = 0.82
    end
    if nDistance > NORMAL_SCALE_DISTANCE then
        local nCoefficient = (BALLOON_VISIBLE_DISTANCE - (nDistance - NORMAL_SCALE_DISTANCE) * 2) / BALLOON_VISIBLE_DISTANCE
        contentScale = contentScale * math.max(DistancelScaleMin, nCoefficient)
    end
    local scaleOffsetX = width*0.5
    local scaleOffsetY = height*0.5*scaley
    local offsetX = baseOffsetX + (1-contentScale)*scaleOffsetX
    local offsetY = baseOffsetY - (1-contentScale)*scaleOffsetY
    local position = GetCharacterTopScreenXYZ(self.characterID)
    if position then
        local scale = (nDistance > NORMAL_SCALE_DISTANCE and (BALLOON_VISIBLE_DISTANCE - (nDistance-NORMAL_SCALE_DISTANCE)*2)/BALLOON_VISIBLE_DISTANCE) or 1
        UIHelper.SetPosition(self._rootNode, position.x * scaleX + offsetX , -position.y * scaley + offsetY )
        UIHelper.SetScale(self._rootNode, scale,scale)
        self.nCycleTimeID = Timer.AddFrameCycle(self, 1 , function ()
            nDistance = GetCharacterDistance(self.characterID, dwPlayerID)
            if Platform.IsWindows() then
                contentScale = 0.82
            else
                contentScale =  1
            end
            if nDistance > NORMAL_SCALE_DISTANCE then
                local nCoefficient = (BALLOON_VISIBLE_DISTANCE - (nDistance - NORMAL_SCALE_DISTANCE) * 2) / BALLOON_VISIBLE_DISTANCE
                contentScale = contentScale * math.max(DistancelScaleMin, nCoefficient)
            end

            if  nDistance > BALLOON_VISIBLE_DISTANCE or contentScale < 0 then
                Timer.DelTimer(self, self.nCycleTimeID)
                self:RemoveNode()
                return
            end
            local position = GetCharacterTopScreenXYZ(self.characterID)
            if position.z > 1 or position.z < 0 then
                Timer.DelTimer(self, self.nCycleTimeID)
                self:RemoveNode()
                return
            end

            offsetX = baseOffsetX + (1-contentScale) * scaleOffsetX
            offsetY = baseOffsetY - (1-contentScale) * scaleOffsetY
            UIHelper.SetPosition(self._rootNode, position.x * scaleX + offsetX, -position.y * scaley + offsetY)
            UIHelper.SetScale(self._rootNode, contentScale, contentScale)
        end)
    end
end

function NpcHeadBalloon:RemoveNode()
    UIHelper.RemoveFromParent(self._rootNode, true)
end


function NpcHeadBalloon:IsStoryChannel()
    if  self.nChannel == PLAYER_TALK_CHANNEL.STORY_NPC
        or self.nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_YELL
        or self.nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_WHISPER
        or self.nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_SAY_TO
        or self.nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_YELL_TO
        or self.nChannel == PLAYER_TALK_CHANNEL.STORY_PLAYER
    then
        return true
    end

    return false
end

return NpcHeadBalloon