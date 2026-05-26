local UIMonsterBookChooseBuff = class("UIMonsterBookChooseBuff")
local BUFF_SHELL = {
    "UIAtlas2_Baizhan_BuffChoose_Img_Buff01",
    "UIAtlas2_Baizhan_BuffChoose_Img_Buff02",
    "UIAtlas2_Baizhan_BuffChoose_Img_Buff03",
}
function UIMonsterBookChooseBuff:OnEnter(nBookIndex, nSum, bDisableSound)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData(nBookIndex, nSum)
    self:UpdateInfo()
end

function UIMonsterBookChooseBuff:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookChooseBuff:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnContinue, EventType.OnClick, function ()
        RemoteCallToServer("On_MonsterBook_BuffConfirm")
        UIMgr.Close(self)
    end)
end

function UIMonsterBookChooseBuff:RegEvent()

end

function UIMonsterBookChooseBuff:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookChooseBuff:InitData(nIndex, nSum)
    self.dwSelectID = nIndex
    if nSum then
        self.nSum = nSum
    else
        self.nSum = 3
    end
    self.bOpen = false
    self.tScriptBooks = {}
end

function UIMonsterBookChooseBuff:UpdateInfo()
    for i = 1, self.nSum do
        self.tScriptBooks[i] = self.tScriptBooks[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetBaizhanBuffCell, self.LayoutBuffList)
        local scriptBook = self.tScriptBooks[i]
        scriptBook:OnEnter(function ()
            if not self.bOpen then
                local tInfo = Table_GetMonsterBookInfo(self.dwSelectID)
                scriptBook:UpdateInfo(tInfo)
                self.bOpen = true
                UIHelper.SetVisible(self.BtnContinue, self.bOpen)
            end
        end)
        UIHelper.SetSpriteFrame(scriptBook.ImgShut, BUFF_SHELL[i])
    end
    UIHelper.SetVisible(self.BtnContinue, self.bOpen)
end

return UIMonsterBookChooseBuff