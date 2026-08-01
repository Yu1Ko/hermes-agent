-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBlackScreenView
-- Date: 2023-06-30 11:42:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBlackScreenView = class("UIBlackScreenView")

function UIBlackScreenView:OnEnter(nFadeOutTime, nFadeInTime, nKeepTime, tFadeColor, bRENDER, bHideUI, tText, bCanEsc)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitData(nFadeOutTime, nFadeInTime, nKeepTime, tFadeColor, bRENDER, bHideUI, tText, bCanEsc)
    self:UpdateInfo()

    UIHelper.FadeNode({self.ImgBg, self.RichText}, 255, self.nFadeOutTime, function()
        if self.nTimer then
            Timer.DelTimer(self, self.nTimer)
        end
        if self.nKeepTime ~= 0 then
            self.nTimer = Timer.Add(self, self.nKeepTime, function()
                UIHelper.FadeNode({self.ImgBg, self.RichText}, 0, self.nFadeInTime, function()
                    UIMgr.Close(self)
                end)
            end)
        else
            UIHelper.FadeNode({self.ImgBg, self.RichText}, 0, self.nFadeInTime, function()
                UIMgr.Close(self)
            end)
        end
    end)

    -- UIHelper.PlayAni(self, self.AniAll, "AniShow", function()

    --     if self.nTimer then
    --         Timer.DelTimer(self, self.nTimer)
    --     end

    --     self.nTimer = Timer.AddFrame(self, self.nKeepTime, function()
    --         UIHelper.PlayAni(self, self.AniAll, "AniHide", function()
    --             UIMgr.Close(self)
    --         end)
    --     end)
    -- end, nil, nFadeInTime <= 8)
end

function UIBlackScreenView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBlackScreenView:BindUIEvent()

end

function UIBlackScreenView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if self.bCanEsc then
            UIMgr.Close(self)
        end
    end)
end

function UIBlackScreenView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIBlackScreenView:InitData(nFadeOutTime, nFadeInTime, nKeepTime, tFadeColor, bRENDER, bHideUI, tText, bCanEsc)
    self.nFadeOutTime = nFadeOutTime / GLOBAL.GAME_FPS
    self.nFadeInTime = nFadeInTime / GLOBAL.GAME_FPS
    self.nKeepTime = nKeepTime / GLOBAL.GAME_FPS
    self.szText = ""
    self.bCanEsc = bCanEsc
    if tText == nil then return end 
    if IsString(tText) then 
        tText = {szText = tText} 
    end
    if table.is_empty(tText) then return end
    for nIndex, tbText in ipairs(tText) do
        self.szText = tbText.szText.."\n"..self.szText
    end
    self.szText = UIHelper.GBKToUTF8(self.szText)
    self.szText = string.gsub(self.szText, "﹃", "\"")
    self.szText = string.gsub(self.szText, "﹄", "\"")
    self.szText = string.gsub(self.szText, "﹁", "'")
    self.szText = string.gsub(self.szText, "﹂", "'")
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBlackScreenView:UpdateInfo()
    UIHelper.SetRichText(self.RichText, self.szText)
    UIHelper.SetOpacity(self.ImgBg, 0)
    UIHelper.SetOpacity(self.RichText, 0)
end


return UIBlackScreenView