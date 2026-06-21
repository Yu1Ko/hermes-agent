-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIHintPvpMoba
-- Date: 2024-07-09 10:30:12
-- Desc: moba 局内提示
-- Prefab: WidgetHintPvpMoba
-- ---------------------------------------------------------------------------------

---@class UIHintPvpMoba
local UIHintPvpMoba = class("UIHintPvpMoba")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIHintPvpMoba:_LuaBindList()
    --- -------------------------- GeneralMsg --------------------------
    self.WidgetGeneralMsg                   = self.WidgetGeneralMsg --- 通用消息组件
    self.GeneralMsgImgBg                    = self.GeneralMsgImgBg --- 阵营颜色背景图片
    self.GeneralMsgLabelMessage             = self.GeneralMsgLabelMessage --- 消息文本

    --- -------------------------- GeneralMsgEx --------------------------
    self.WidgetGeneralMsgEx                 = self.WidgetGeneralMsgEx --- 通用消息ex组件
    self.GeneralMsgExImgBg                  = self.GeneralMsgExImgBg --- 阵营颜色背景图片
    self.GeneralMsgExLabelMessage           = self.GeneralMsgExLabelMessage --- 消息文本
    self.GeneralMsgExSFXAce                 = self.GeneralMsgExSFXAce --- 特效组件

    --- -------------------------- OneSidedMsg --------------------------
    self.WidgetOneSidedMsg                  = self.WidgetOneSidedMsg --- 单侧的消息组件
    self.OneSidedMsgImgBgMessage            = self.OneSidedMsgImgBgMessage --- 消息背景图
    self.OneSidedMsgLabelMessage            = self.OneSidedMsgLabelMessage --- 消息文本
    self.OneSidedMsgImgAvatarFrame          = self.OneSidedMsgImgAvatarFrame --- 头像框
    self.OneSidedMsgImgAvatar               = self.OneSidedMsgImgAvatar --- 头像
    self.OneSidedMsgImgAvatarFrameTail      = self.OneSidedMsgImgAvatarFrameTail --- 头像框的右下角尾巴
    self.OneSidedMsgSFXBg                   = self.OneSidedMsgSFXBg --- 特效组件

    --- -------------------------- TwoSidedMsg --------------------------
    self.WidgetTwoSidedMsg                  = self.WidgetTwoSidedMsg --- 两侧的消息组件

    self.TwoSidedMsgWidgetKillPlayer        = self.TwoSidedMsgWidgetKillPlayer --- 击杀玩家的组件
    self.TwoSidedMsgImgKillPlayerBg         = self.TwoSidedMsgImgKillPlayerBg --- 击杀玩家的背景图
    self.TwoSidedMsgLabelKillPlayer         = self.TwoSidedMsgLabelKillPlayer --- 击杀玩家的消息

    self.TwoSidedMsgWidgetKillNonPlayer     = self.TwoSidedMsgWidgetKillNonPlayer --- 击杀非玩家的组件
    self.TwoSidedMsgImgKillNonPlayerBg      = self.TwoSidedMsgImgKillNonPlayerBg --- 击杀非玩家的背景图
    self.TwoSidedMsgLabelKillNonPlayer      = self.TwoSidedMsgLabelKillNonPlayer --- 击杀非玩家的文本

    self.TwoSidedMsgWidgetSFX               = self.TwoSidedMsgWidgetSFX --- 特效组件的上层组件
    self.TwoSidedMsgSFXRed                  = self.TwoSidedMsgSFXRed --- 红色特效组件
    self.TwoSidedMsgSFXBlue                 = self.TwoSidedMsgSFXBlue --- 蓝色特效组件

    self.TwoSidedMsgWidgetHeadLeft          = self.TwoSidedMsgWidgetHeadLeft --- 左侧头像组件
    self.TwoSidedMsgLeftImgAvatarFrame      = self.TwoSidedMsgLeftImgAvatarFrame --- 左侧头像框图片
    self.TwoSidedMsgLeftMaskPlayerAvatar    = self.TwoSidedMsgLeftMaskPlayerAvatar --- 左侧玩家头像组件
    self.TwoSidedMsgLeftImgPlayerAvatar     = self.TwoSidedMsgLeftImgPlayerAvatar --- 左侧玩家头像图片
    self.TwoSidedMsgLeftSFXPlayerAvatar     = self.TwoSidedMsgLeftSFXPlayerAvatar --- 左侧玩家头像特效组件
    self.TwoSidedMsgLeftImgNonPlayerAvatar  = self.TwoSidedMsgLeftImgNonPlayerAvatar --- 左侧非玩家头像图片
    self.TwoSidedMsgLeftLabelName           = self.TwoSidedMsgLeftLabelName --- 左侧名字

    self.TwoSidedMsgWidgetHeadRight         = self.TwoSidedMsgWidgetHeadRight --- 右侧头像组件
    self.TwoSidedMsgRightImgAvatarFrame     = self.TwoSidedMsgRightImgAvatarFrame --- 右侧头像框图片
    self.TwoSidedMsgRightMaskPlayerAvatar   = self.TwoSidedMsgRightMaskPlayerAvatar --- 右侧玩家头像组件
    self.TwoSidedMsgRightImgPlayerAvatar    = self.TwoSidedMsgRightImgPlayerAvatar --- 右侧玩家头像图片
    self.TwoSidedMsgRightSFXPlayerAvatar    = self.TwoSidedMsgRightSFXPlayerAvatar --- 右侧玩家头像特效组件
    self.TwoSidedMsgRightImgNonPlayerAvatar = self.TwoSidedMsgRightImgNonPlayerAvatar --- 右侧非玩家头像图片
    self.TwoSidedMsgRightImgBgKill          = self.TwoSidedMsgRightImgBgKill --- 右侧击杀背景图
    self.TwoSidedMsgRightLabelName          = self.TwoSidedMsgRightLabelName --- 右侧名字

    self.TwoSidedMsgLayoutAssists           = self.TwoSidedMsgLayoutAssists --- 助攻的layout
    self.TwoSidedMsgLabelAssists            = self.TwoSidedMsgLabelAssists --- 助攻标题的label
    self.tTwoSidedMsgAssistsWidgetHeadList  = self.tTwoSidedMsgAssistsWidgetHeadList --- 助攻小头像组件挂载节点列表
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIHintPvpMoba:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIHintPvpMoba:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHintPvpMoba:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHintPvpMoba:BindUIEvent()

end

function UIHintPvpMoba:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHintPvpMoba:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHintPvpMoba:UpdateInfoGeneralMsg(szMsg, szBgImgPath)
    UIHelper.SetVisible(self.WidgetGeneralMsg, true)

    UIHelper.SetString(self.GeneralMsgLabelMessage, szMsg)
    UIHelper.SetSpriteFrame(self.GeneralMsgImgBg, szBgImgPath)
end

function UIHintPvpMoba:UpdateInfoGeneralMsgEx(szMessage, szBgImgPath, szSfxPath)
    UIHelper.SetVisible(self.WidgetGeneralMsgEx, true)

    UIHelper.SetString(self.GeneralMsgExLabelMessage, szMessage)
    UIHelper.SetSpriteFrame(self.GeneralMsgExImgBg, szBgImgPath)
    UIHelper.SetSFXPath(self.GeneralMsgExSFXAce, szSfxPath)
end

function UIHintPvpMoba:UpdateInfoOneSidedMsg(szMessage, szMsgBgImgPath, szImgAvatarPath, szImgAvatarFramePath, szImgAvatarFrameTailPath)
    UIHelper.SetVisible(self.WidgetOneSidedMsg, true)

    UIHelper.SetString(self.OneSidedMsgLabelMessage, szMessage)
    UIHelper.SetSpriteFrame(self.OneSidedMsgImgBgMessage, szMsgBgImgPath)
    UIHelper.SetSpriteFrame(self.OneSidedMsgImgAvatar, szImgAvatarPath)
    UIHelper.SetSpriteFrame(self.OneSidedMsgImgAvatarFrame, szImgAvatarFramePath)
    UIHelper.SetSpriteFrame(self.OneSidedMsgImgAvatarFrameTail, szImgAvatarFrameTailPath)
end

---@param tLeftInfo table 左侧信息 {bAlly, true, szPlayerName, nKungfuID} or {bAlly, false, nNonPlayerIndex}
---@param tRightInfo table 右侧信息 {bAlly, true, szPlayerName, nKungfuID} or {bAlly, false, nNonPlayerIndex}
---@param aAssistKillKungfuIDs number[] 助攻玩家心法ID列表
---@param szCenterBgImgPath string 中间背景图片路径
---@param szCenterTopImgPath string 上方边框图片（vk不使用该部分）
---@param szCenterBottomImgPath string 下方边框图片（vk不使用该部分）
---@param szMessage string 消息文本
---@param szSfxPath string 特效 1 路径
---@param szSfx2Path string 特效 2 路径
function UIHintPvpMoba:UpdateInfoTwoSidedMsg(tLeftInfo, tRightInfo, aAssistKillKungfuIDs, szCenterBgImgPath, szCenterTopImgPath, szCenterBottomImgPath, szMessage, szSfxPath, szSfx2Path)
    UIHelper.SetVisible(self.WidgetTwoSidedMsg, true)

    --- -------------------------------- 中间部分 --------------------------------
    local bRightIsPlayer = tRightInfo[2]

    UIHelper.SetVisible(self.TwoSidedMsgWidgetKillPlayer, bRightIsPlayer)
    UIHelper.SetVisible(self.TwoSidedMsgWidgetKillNonPlayer, not bRightIsPlayer)
    if bRightIsPlayer then
        --- 击杀了玩家
        UIHelper.SetString(self.TwoSidedMsgLabelKillPlayer, szMessage)
        UIHelper.SetSpriteFrame(self.TwoSidedMsgImgKillPlayerBg, szCenterBgImgPath)
    else
        --- 击杀了非玩家
        UIHelper.SetString(self.TwoSidedMsgLabelKillNonPlayer, szMessage)
        UIHelper.SetSpriteFrame(self.TwoSidedMsgImgKillNonPlayerBg, szCenterBgImgPath)
    end

    UIHelper.SetVisible(self.TwoSidedMsgSFXRed, szSfxPath and szSfxPath ~= "")
    UIHelper.SetVisible(self.TwoSidedMsgSFXBlue, szSfx2Path and szSfx2Path ~= "")

    UIHelper.SetSFXPath(self.TwoSidedMsgSFXRed, szSfxPath)
    UIHelper.SetSFXPath(self.TwoSidedMsgSFXBlue, szSfx2Path)

    --- -------------------------------- 两侧 --------------------------------
    self:UpdateLeftOrRightAvatar(true, tLeftInfo)
    self:UpdateLeftOrRightAvatar(false, tRightInfo)

    --- -------------------------------- 下方 --------------------------------
    self:UpdateAssistPlayers(aAssistKillKungfuIDs)
end

--- 非玩家单位的id => { 蓝色头像路径, 红色头像路径 }
local tNonPlayerIdToBlueAndRedAvatarPath = {
    [1] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba7.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba7.png" }, --- 灵兽

    [2] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba1.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba1.png" }, --- 煞星龙兽
    [3] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba2.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba2.png" }, --- 凶星龙兽

    [4] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba4.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba5.png" }, --- 朱雀圣象
    [5] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba3.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba6.png" }, --- 玄武圣象

    [6] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba4.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba5.png" }, --- 朱雀星辉塔
    [7] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba3.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba6.png" }, --- 玄武星辉塔

    [8] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba4.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba5.png" }, --- 朱雀护阵星辉塔
    [9] = { "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba3.png", "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba6.png" }, --- 玄武护阵星辉塔
}

---@param tObjectInfo table 单侧信息 {bAlly, true, szPlayerName, nKungfuID} or {bAlly, false, nNonPlayerIndex}
function UIHintPvpMoba:UpdateLeftOrRightAvatar(bLeft, tObjectInfo)
    tObjectInfo = tObjectInfo or {}

    local imgAvatarFrame, maskPlayerAvatar, imgPlayerAvatar, sFXPlayerAvatar, imgNonPlayerAvatar, labelName, imgBgKill

    if bLeft then
        imgAvatarFrame, maskPlayerAvatar, imgPlayerAvatar, sFXPlayerAvatar, imgNonPlayerAvatar, labelName, imgBgKill = self.TwoSidedMsgLeftImgAvatarFrame,
        self.TwoSidedMsgLeftMaskPlayerAvatar, self.TwoSidedMsgLeftImgPlayerAvatar, self.TwoSidedMsgLeftSFXPlayerAvatar,
        self.TwoSidedMsgLeftImgNonPlayerAvatar, self.TwoSidedMsgLeftLabelName, nil
    else
        imgAvatarFrame, maskPlayerAvatar, imgPlayerAvatar, sFXPlayerAvatar, imgNonPlayerAvatar, labelName, imgBgKill = self.TwoSidedMsgRightImgAvatarFrame,
        self.TwoSidedMsgRightMaskPlayerAvatar, self.TwoSidedMsgRightImgPlayerAvatar, self.TwoSidedMsgRightSFXPlayerAvatar,
        self.TwoSidedMsgRightImgNonPlayerAvatar, self.TwoSidedMsgRightLabelName, self.TwoSidedMsgRightImgBgKill
    end

    local bAlly   = tObjectInfo[1]
    local bPlayer = tObjectInfo[2]
    if bAlly then
        UIHelper.SetSpriteFrame(imgAvatarFrame, "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue1.png")
    else
        UIHelper.SetSpriteFrame(imgAvatarFrame, "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed1.png")
    end

    UIHelper.SetVisible(maskPlayerAvatar, bPlayer)
    UIHelper.SetVisible(imgNonPlayerAvatar, not bPlayer)

    if bPlayer then
        local szPlayerName = tObjectInfo[3]
        local nKungfuID    = tObjectInfo[4]

        UIHelper.SetString(labelName, UIHelper.GBKToUTF8(szPlayerName))

        local szIconPath = PlayerKungfuImg[nKungfuID]
        UIHelper.SetSpriteFrame(imgPlayerAvatar, szIconPath)
    else
        local nNonPlayerIndex = tObjectInfo[3]
        local tUIInfo         = Table_GetMobaBattleNonPlayerInfo(nNonPlayerIndex)

        UIHelper.SetString(labelName, UIHelper.GBKToUTF8(tUIInfo.szName))

        local szNonPlayerAvatar
        local szBlueAvatar, szRedAvatar = table.unpack(tNonPlayerIdToBlueAndRedAvatarPath[nNonPlayerIndex])
        if bAlly then
            szNonPlayerAvatar = szBlueAvatar
        else
            szNonPlayerAvatar = szRedAvatar
        end
        UIHelper.SetSpriteFrame(imgNonPlayerAvatar, szNonPlayerAvatar)
    end

    if imgBgKill then
        UIHelper.SetVisible(imgBgKill, true)
    end
end

---@param aAssistKillKungfuIDs number[] 助攻玩家心法ID列表
function UIHintPvpMoba:UpdateAssistPlayers(aAssistKillKungfuIDs)
    UIHelper.SetVisible(self.TwoSidedMsgLayoutAssists, #aAssistKillKungfuIDs > 0)
    if #aAssistKillKungfuIDs > 0 then
        for idx, imgAssistKungfu in ipairs(self.tTwoSidedMsgAssistsWidgetHeadList) do
            local nKungfuID  = aAssistKillKungfuIDs[idx]

            local widgetHead = UIHelper.GetParent(imgAssistKungfu)
            UIHelper.SetVisible(widgetHead, nKungfuID ~= nil)

            if nKungfuID then
                local szIconPath = PlayerKungfuImg[nKungfuID]
                UIHelper.SetSpriteFrame(imgAssistKungfu, szIconPath)
            end
        end

        UIHelper.CascadeDoLayoutDoWidget(self.TwoSidedMsgLayoutAssists, true, true)
    end
end

return UIHintPvpMoba