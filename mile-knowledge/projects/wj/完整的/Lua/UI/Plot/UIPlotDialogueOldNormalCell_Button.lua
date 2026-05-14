-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIPlotDialogueOldNormalCell_Button
-- Date: 2022-11-24 14:58:15
-- Desc: 老对话框 按钮
-- ---------------------------------------------------------------------------------

local szDefaultBg = "UIAtlas2_Public_PublicButton_PublicButton1_PublicButton_Erji"

local UIPlotDialogueOldNormalCell_Button = class("UIPlotDialogueOldNormalCell_Button")

function UIPlotDialogueOldNormalCell_Button:OnEnter(tbData)
    self.tbData = tbData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPlotDialogueOldNormalCell_Button:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldNormalCell_Button:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnContent_1, EventType.OnClick, function(btn)
        if self.tbData then
            if IsFunction(self.tbData.callback) then
                self.tbData.callback()
            end
        end
    end)
end

function UIPlotDialogueOldNormalCell_Button:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlotDialogueOldNormalCell_Button:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlotDialogueOldNormalCell_Button:UpdateInfo()

    local szContent = self.tbData.szContent
    szContent = string.gsub(szContent, "^[%s+]", "")--去掉开头空格
    UIHelper.SetRichText(self.RichTextContent, szContent, true)
    UIHelper.SetSpriteFrame(self.ImgContentIcon, self.tbData.szIconName)
    UIHelper.SetSpriteFrame(self.Background, self.tbData.szIconBg or szDefaultBg)

    local nHeight = UIHelper.GetHeight(self.RichTextContent) + 30
    if nHeight < 100 then nHeight = 100 end
    UIHelper.SetContentSize(self.BtnContent_1, UIHelper.GetWidth(self.BtnContent_1), nHeight)
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)
end


return UIPlotDialogueOldNormalCell_Button