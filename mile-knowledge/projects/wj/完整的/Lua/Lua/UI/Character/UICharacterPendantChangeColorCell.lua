-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantChangeColorCell
-- Date: 2024-06-14 14:08:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterPendantChangeColorCell = class("UICharacterPendantChangeColorCell")

function UICharacterPendantChangeColorCell:OnEnter(tbInfo, funcClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- TogType
    -- LayoutContent
    -- tbColorCell
    self.tbInfo = tbInfo
    self.funcClickCallback = funcClickCallback
    self:UpdateInfo()
end

function UICharacterPendantChangeColorCell:OnExit()
    self.bInit = false
end

function UICharacterPendantChangeColorCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogType, EventType.OnClick, function(btn)
        if self.funcClickCallback then
            self.funcClickCallback()
        end
    end)

end

function UICharacterPendantChangeColorCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end
function UICharacterPendantChangeColorCell:UpdateInfo()
    local tConfig = self:GetCloakColorConfig(self.tbInfo.dwItemIndex)
    if not tConfig then
        return
    end
    for i, widget in ipairs(self.tbColorCell) do
        local script = UIHelper.GetBindScript(widget)
        local nColorID = self.tbInfo["nColorID" .. i]
        if nColorID == 1 then
            UIHelper.SetVisible(script.WidgetDefault, true)
            UIHelper.SetVisible(script.ImgColor, false)
        else
            UIHelper.SetVisible(script.WidgetDefault, false)
            UIHelper.SetVisible(script.ImgColor, true)

            local tRGB = tConfig[i][nColorID]
            UIHelper.SetColor(script.ImgColor, cc.c3b(tRGB[2], tRGB[3], tRGB[4]))
        end
    end
end

function UICharacterPendantChangeColorCell:GetCloakColorConfig(dwPendantID)
    local tColorList = {}
    local nCount = g_tTable.CloakColorChange:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CloakColorChange:GetRow(i)
        if tLine.dwPendantID == dwPendantID then
            if not tColorList[tLine.nBlock] then
                tColorList[tLine.nBlock] = {}
            end
            table.insert(tColorList[tLine.nBlock], {tLine.nA, tLine.nR, tLine.nG, tLine.nB})
        end
    end

    return tColorList
end


return UICharacterPendantChangeColorCell