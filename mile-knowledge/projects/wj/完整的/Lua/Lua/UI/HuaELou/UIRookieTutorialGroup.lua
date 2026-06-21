-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRookieTutorialGroup
-- Date: 2024-04-03 16:45:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRookieTutorialGroup = class("UIRookieTutorialGroup")
local richImg = "<img src='UIAtlas2_Public_PublicPanel_PublicPanel1_TitielHintImg' width='12' height='12'/>"

function UIRookieTutorialGroup:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    self.dwOperatActID = dwOperatActID

    self:UpdateTimeInfo(tActivity)
    self:UpdateInfo()
    self:UpdateBtnPos(tActivity)
end

function UIRookieTutorialGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRookieTutorialGroup:BindUIEvent()

end

function UIRookieTutorialGroup:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRookieTutorialGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRookieTutorialGroup:UpdateInfo()
    if self.RichText then
        if self.dwOperatActID  == 179 then
            local szText =
            richImg.." 完成<href=LinkActivity\\29><color=#DDDF07>[大战！系列]</color></href><href=LinkActivity\\678><color=#DDDF07>[绝漠疾尘争险道]</color></href>任务额外获得一份不占周上限的数值奖励，另可额外获得至多一份【福禄宝箱・山海源流】和【玉灵淬石】；\n"..
            richImg.." 战阶结算速度提升至200%；每周前五场完成<href=LinkActivity\\570><color=#DDDF07>[名剑大会]</color></href>获胜时，额外获得一倍威名点（占周上限）。".."\n"..
            richImg.." <href=PanelLink\\FBlistRaid><color=#DDDF07> [130级25人团队秘境]</color></href>（不含25人挑战空城殿、25人挑战缚罪之渊）首领均会额外掉落一件装备（与共战江湖叠加）。<href=FBlist\\723><color=#DDDF07>[25人普通会战弓月城]</color></href>秘境和<href=FBlist\\708><color=#DDDF07>[25人英雄太极宫]</color></href>秘境的最终首领额外掉落2个【于阗玉邦】系列附魔。".."\n"..
            richImg.." <href=LinkActivity\\790><color=#DDDF07> [坠焰熔晶淬刃锋]</color></href><href=BattleFieldQueue\\296><color=#DDDF07>[孤城瀚海斩狂澜]</color></href><href=LinkActivity\\579><color=#DDDF07>[江湖百年风霜事]</color></href><href=LinkActivity\\717><color=#DDDF07>[传信邻里间]</color></href>任务奖励增加；<href=BattleFieldQueue\\709><color=#DDDF07>[奇境寻宝]</color></href>命定宝箱额外掉落一件紫色宝藏。".."\n\n"..
            richImg.." <color=#E2F6FB>具体内容见详情。</color>"
            UIHelper.SetRichText(self.RichText, szText)
        end
    end
end

function UIRookieTutorialGroup:UpdateBtnPos(tActivity)
    if not self.tbPublicBtn then
        return
    end

    for k, PublicBtn in ipairs(self.tbPublicBtn) do
        local nBtnID, nBtnPosX, nBtnPosY = self:GetBtnInfo(k, tActivity)

        local scriptBtn = UIHelper.GetBindScript(PublicBtn) assert(scriptBtn)
        if nBtnID ~= 0 then
            scriptBtn:OnEnter(nBtnID)
        end
        UIHelper.SetVisible(PublicBtn, nBtnID ~= 0 or (scriptBtn.nID ~= nil and tonumber(scriptBtn.nID) ~= 0))

        if (nBtnPosX ~= 0 or nBtnPosY~= 0)  then
            UIHelper.SetPosition(PublicBtn, nBtnPosX, nBtnPosY)
        end
    end

    if tActivity.szbgImgPath ~= "" and self.BgGift then
        UIHelper.SetTexture(self.BgGift, tActivity.szbgImgPath)
    end
end

function UIRookieTutorialGroup:GetBtnInfo(k, tActivity)
    local nBtnID, nBtnPosX, nBtnPosY
    if k == 1 then
        nBtnID = tActivity.nBtnID
        nBtnPosX = tActivity.tbBtnPosXY[1]
        nBtnPosY = tActivity.tbBtnPosXY[2]
    elseif k ==2 then
        nBtnID = tActivity.nBtnID2
        nBtnPosX = tActivity.tbBtn2PosXY[1]
        nBtnPosY = tActivity.tbBtn2PosXY[2]
    elseif k ==3 then
        nBtnID = tActivity.nBtnID3
        nBtnPosX = tActivity.tbBtn3PosXY[1]
        nBtnPosY = tActivity.tbBtn3PosXY[2]
    end

    return nBtnID, nBtnPosX, nBtnPosY
end

function UIRookieTutorialGroup:UpdateTimeInfo(tActivity)
    local tLine = Table_GetOperActyInfo(self.dwOperatActID) assert(tLine)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    if tActivity.szbgImgPath ~= "" and self.BgGift then
        UIHelper.SetTexture(self.BgGift, tActivity.szbgImgPath)
    end


    if self.LabelMiddle then
        local tStartTime, tEndTime = tLine.tStartTime, tLine.tEndTime
        local nStart = tStartTime[1]
        local nEnd = tEndTime and tEndTime[1]
        local szText = HuaELouData.GetTimeShowText(nStart, nEnd)
        if tLine.szCustomTime ~= "" then
            szText = UIHelper.GBKToUTF8(tLine.szCustomTime)
        end

        UIHelper.SetString(self.LabelMiddle, szText)
    end
end

return UIRookieTutorialGroup