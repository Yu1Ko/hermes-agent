-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent1
-- Date: 2022-11-15 15:45:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent1 = class("UIItemTipContent1")

function UIItemTipContent1:OnEnter(tbInfo)
    if not tbInfo then
        return
    end

    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent1:OnExit()
    self.bInit = false
end

function UIItemTipContent1:BindUIEvent()

end

function UIItemTipContent1:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent1:UpdateInfo()
    local bShow = false
    local bShowLine1 = false
    local bShowLine2 = false
    local bShowSingleText = false

    if not self.tbInfo or table.is_empty(self.tbInfo) then
        UIHelper.SetVisible(self._rootNode, false)
        UIHelper.SetVisible(self.ImgLine, false)
    elseif #self.tbInfo == 1 and self.tbInfo[1] ~= "" then
         bShowSingleText = true
         bShow = true
         UIHelper.SetRichText(self.RichTextSingle, self.tbInfo[1])
    else
        for i = 1, 4, 1 do
            if self.tbInfo[i] and self.tbInfo[i] ~= "" and self["RichTextAttri" .. i] then
                UIHelper.SetVisible(self["RichTextAttri" .. i], true)
                UIHelper.SetRichText(self["RichTextAttri" .. i], self.tbInfo[i])
                if i == 1 or i == 4 then
                    bShowLine1 = true
                elseif i == 2 or i == 3 then
                    bShowLine2 = true
                    if i == 3 then
                        UIHelper.SetVisible(self["RichTextAttri" .. 2], true)
                    end
                end
                bShow = true
            else
                UIHelper.SetVisible(self["RichTextAttri" .. i], false)
            end
        end
    end
    
    UIHelper.SetVisible(self.RichTextSingle, bShowSingleText)
    UIHelper.SetVisible(self.LayoutLine1, bShowLine1)
    UIHelper.SetVisible(self.LayoutLine2, bShowLine2)
    UIHelper.SetVisible(self._rootNode, bShow)
    UIHelper.SetVisible(self.ImgLine, bShow)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, false, true)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIItemTipContent1