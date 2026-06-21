-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventurePageContent
-- Date: 2023-12-27 19:39:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAdventurePageContent = class("UIAdventurePageContent")

function UIAdventurePageContent:OnEnter(fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnAction = fnAction

    local nTotalWidth, nTotalHeight = UIHelper.GetContentSize(self.LabelContent)
    self.nWidth = nTotalWidth
    self.nHeight = nTotalHeight
    self.nFontSize = UIHelper.GetFontSize(self.LabelContent)
end

function UIAdventurePageContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventurePageContent:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPage, EventType.OnClick, function ()
        self.fnAction()
    end)

    UIHelper.BindUIEvent(self.BtnMoHe, EventType.OnClick, function()
        if self.funcMoHeCallback then
            self.funcMoHeCallback()
        end
    end)
end

function UIAdventurePageContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAdventurePageContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventurePageContent:UpdateInfo()

end

function UIAdventurePageContent:CalcLimitWidth(nFontSize)
    local nLine = math.floor((self.nHeight + 15) / nFontSize)
    return self.nWidth * nLine
end

function UIAdventurePageContent:SetContentText(szContent)
    local tContent = string.split(szContent, "\n")
    for i = self.nFontSize, 1, -1 do
        local nLimitWidth = self:CalcLimitWidth(i)
        local nTotalWidth = 0
        for _, sz in ipairs(tContent) do
            local nWidth = UIHelper.GetUtf8Width(sz, i)
            local nFixWidth = math.ceil(nWidth / self.nWidth) * self.nWidth
            nTotalWidth = nTotalWidth + nFixWidth
            if nTotalWidth > nLimitWidth then
                break
            end
        end
        if nTotalWidth <= nLimitWidth then
            UIHelper.SetFontSize(self.LabelContent, i)
            break
        end
    end
    UIHelper.SetRichText(self.LabelContent, string.format("<color=#5f4e3a>%s</c>", szContent))
end

function UIAdventurePageContent:SetClickMoHeCallback(funcMoHeCallback)
    self.funcMoHeCallback = funcMoHeCallback
end

return UIAdventurePageContent