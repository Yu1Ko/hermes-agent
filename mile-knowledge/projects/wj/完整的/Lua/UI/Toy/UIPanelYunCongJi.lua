-- ---------------------------------------------------------------------------------
-- Author: 贾宇然
-- Name: UIPanelYunCongJi
-- Date: 2024.4.11
-- Desc: 玩具-云从集
-- Prefab: PanelYunCongJi
-- ---------------------------------------------------------------------------------

local DataModel = {}
local tbRImgList = {
    ["ui/Image/NPCRoster/NPC/LiWangShengR.tga"] = "mui/Texture/Toy/Yuncongji/LiWangShengR.png",
    ["ui/Image/NPCRoster/NPC/ChengShiR.tga"] = "mui/Texture/Toy/Yuncongji/ChengShiR.png",
    ["ui/Image/NPCRoster/NPC/DuYueKongR.tga"] = "mui/Texture/Toy/Yuncongji/DuYueKongR.png",
    ["ui/Image/NPCRoster/NPC/GuoYanR.tga"] = "mui/Texture/Toy/Yuncongji/GuoYanR.png",
    ["ui/Image/NPCRoster/NPC/LuRongR.tga"] = "mui/Texture/Toy/Yuncongji/LuRongR.png",
    ["ui/Image/NPCRoster/NPC/WuYaoTianR.tga"] = "mui/Texture/Toy/Yuncongji/WuYaoTianR.png",
    ["ui/Image/NPCRoster/NPC/YuanYuZhaoR.tga"] = "mui/Texture/Toy/Yuncongji/YuanYuZhaoR.png",
    ["ui/Image/NPCRoster/NPC/YueQuanHuaiR.tga"] = "mui/Texture/Toy/Yuncongji/YueQuanHuaiR.png",
    ["ui/Image/NPCRoster/NPC/ZhuoFengMingR.tga"] = "mui/Texture/Toy/Yuncongji/ZhuoFengMingR.png",
}

local tbLImgList = {
    ["ui/Image/NPCRoster/NPC/LiWangSheng.tga"] = "mui/Texture/Toy/Yuncongji/LiWangSheng.png",
    ["ui/Image/NPCRoster/NPC/ChengShi.tga"] = "mui/Texture/Toy/Yuncongji/ChengShi.png",
    ["ui/Image/NPCRoster/NPC/DuYueKong.tga"] = "mui/Texture/Toy/Yuncongji/DuYueKong.png",
    ["ui/Image/NPCRoster/NPC/GuoYan.tga"] = "mui/Texture/Toy/Yuncongji/GuoYan.png",
    ["ui/Image/NPCRoster/NPC/LuRong.tga"] = "mui/Texture/Toy/Yuncongji/LuRong.png",
    ["ui/Image/NPCRoster/NPC/WuYaoTian.tga"] = "mui/Texture/Toy/Yuncongji/WuYaoTian.png",
    ["ui/Image/NPCRoster/NPC/YuanYuZhao.tga"] = "mui/Texture/Toy/Yuncongji/YuanYuZhao.png",
    ["ui/Image/NPCRoster/NPC/YueQuanHuai.tga"] = "mui/Texture/Toy/Yuncongji/YueQuanHuai.png",
    ["ui/Image/NPCRoster/NPC/ZhuoFengMing.tga"] = "mui/Texture/Toy/Yuncongji/ZhuoFengMing.png",
}

function DataModel.Init()
    DataModel.NPCInfo = Table_GetNPCRoster()
    DataModel.nCurrentPage = 1
    DataModel.nTotalCount = DataModel.NPCInfo and #DataModel.NPCInfo or 1
end

function DataModel.GetNPCInfo(nPage)
    if DataModel.NPCInfo then
        return DataModel.NPCInfo[nPage]
    end
end

function DataModel.GetCurrentPage()
    return DataModel.nCurrentPage
end

function DataModel.TurnPage(bNext)
    if bNext then
        DataModel.nCurrentPage = DataModel.nCurrentPage + 1
    else
        DataModel.nCurrentPage = DataModel.nCurrentPage - 1
    end

    DataModel.nCurrentPage = math.max(DataModel.nCurrentPage, 1)
    DataModel.nCurrentPage = math.min(DataModel.nCurrentPage, DataModel.nTotalCount)
end

function DataModel.UnInit()
    DataModel.NPCInfo = nil
end

---@class UIPanelYunCongJi
local UIPanelYunCongJi = class("UIPanelYunCongJi")

function UIPanelYunCongJi:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    DataModel.Init()
    self:UpdateInfo()
end

function UIPanelYunCongJi:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelYunCongJi:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnFlipLeft, EventType.OnClick, function()
        DataModel.TurnPage(false)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnFlipRight, EventType.OnClick, function()
        DataModel.TurnPage(true)
        self:UpdateInfo()
    end)
end

function UIPanelYunCongJi:RegEvent()

end

function UIPanelYunCongJi:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelYunCongJi:UpdateInfo()
    local nCurPage = DataModel.nCurrentPage
    local tInfo = DataModel.GetNPCInfo(nCurPage)
    if not tInfo then
        return
    end

    if tInfo.szImageLPath then
        UIHelper.SetTexture(self.ImgLeft, tbLImgList[tInfo.szImageLPath], true)
    end

    if tInfo.szImageRPath then
        UIHelper.SetTexture(self.ImgRight, tbRImgList[tInfo.szImageRPath], true)
    end

    UIHelper.SetVisible(self.BtnFlipLeft, nCurPage ~= 1)
    UIHelper.SetVisible(self.BtnFlipRight, nCurPage ~= DataModel.nTotalCount)
end

return UIPanelYunCongJi