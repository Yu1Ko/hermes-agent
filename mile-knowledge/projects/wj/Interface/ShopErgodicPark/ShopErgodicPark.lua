Shop = {}
local ShopErgodic = {}
local CameraRotate = {}
local ShopGood = {}
local ShopHomeGoods = {}
local ShopHomeGoodsTitle = {}
local ShopTitle = {}
local pCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1
local bFlag = true
local szFilePath=SearchPanel.szInterfacePath.."ShopErgodicPark/ShopMation.ini"
-- 记录商城 总目录 一级目录 二级目录 商城商品dwLogicID  商城商品名称
local szHead="Contents\tFirstdirectory\tSecondarydirectory\tGoodsdwID\tGoodName\n"
local szGoodsFilePath=SearchPanel.szCurrentInterfacePath.."ShopRunMap.tab"
local file=io.open(szGoodsFilePath,"w")
file:write(szHead)
local szContent=""
--读取ini文件
LoginMgr.Log("Shop",szFilePath)
local ini = Ini.Open(szFilePath)
local szShopErgodicTitleTime =ini:ReadString("ShopMation", "ShopErgodicTitleTime", "")           -- 商城目录间隔的时间
local szShopGoodTime = ini:ReadString("ShopMation", "ShopGoodTime", "")                          -- 商城商品循环的时间
local szCameraSwitch = ini:ReadString("ShopMation", "CameraSwitch", "")                           -- 摄像机是否启动旋转
local szGoodsCameraTime = ini:ReadString("ShopMation", "GoodsCameraTime", "")                    -- 人物摄像机循环的时间
local szGoodsHomeTime = ini:ReadString("ShopMation", "GoodsHomeTime", "")                        -- 限时抢购商品循环的时间
-- 转为number
ShopErgodic.nTime=tonumber(szShopErgodicTitleTime)
local nShopGoodsTime=tonumber(szShopGoodTime)
local nCameraTime=tonumber(szGoodsCameraTime)
local nHomeTime = tonumber(szGoodsHomeTime)
local nCameraSwitch = tonumber(szCameraSwitch)
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]
local tbGoodsList =  {} -- 商品数据

ShopErgodic.bSwitchCount = false -- 是否开启循环遍历
ShopErgodic.nErgodicCount = 2 -- 循环次数默认2次
ShopErgodic.nErgodicLine = 1 -- 当前遍历的次数
local bErgodic = true
function Shop.ApiCount(bSwitchCount,nErgodicCount)
    if tonumber(bSwitchCount) == 1 then
        ShopErgodic.bSwitchCount = true
    end
    ShopErgodic.nErgodicCount = tonumber(nErgodicCount)
end

-- 商店左侧栏目初始化
local nShopTitle = false
local tbShopTitle = {}          -- 一级目录
local tbShopTitleSecondary= {}  -- 二级目录
function ShopTitle.initialization()
    -- 选择左侧更改商品
    for _, tbClass in ipairs(CoinShopData.GetList()) do
        if tbClass.tList and #tbClass.tList > 0 then
            for _, tbTitle in ipairs(tbClass.tList) do
                local tbTemporary = {}
                local szName = tbTitle.szName
                local nType = tbTitle.nType
                local nRewardsClass = tbTitle.nRewardsClass
                local nSubClass = tbTitle.nSubClass
                -- 小玩意和遗失的美好被挑出来了 记录的时候显示为nil 这里进行单独的赋值
                if nType == 6 and nRewardsClass == 7 then
                    tbTemporary = {nType,nRewardsClass,szName,UTF8ToGBK("小玩意儿"),nSubClass}
                elseif nType == 6 and nRewardsClass == 10 then
                    tbTemporary = {nType,nRewardsClass,szName,UTF8ToGBK("遗失的美好"),nSubClass}
                else
                    tbTemporary = {nType,nRewardsClass,szName,tbClass.szTitleName,nSubClass}
                end
                -- print(szName,nType,nRewardsClass,nSubClass)
                table.insert(tbShopTitleSecondary, tbTemporary)
            end
            table.insert(tbShopTitle,tbShopTitleSecondary)
        end
        tbShopTitleSecondary = {}
    end
end

-- 商城每个目录对应的商品数据
-- 获取商品数据
-- nType nClass 栏目数据 
function ShopGoodinitialization(nType,nClass,nSubClass)
    -- 商城对应的商品数据
    local tbTitle = CoinShop_GetTitleInfo(nType, nClass)
    if tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        -- 外装
        tbGoodsList = CoinShopData.GetExteriorList(tbTitle.nRewardsClass)
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
        if nSubClass == nil then
            tbGoodsList = CoinShopData.GetRewardsList(tbTitle.nRewardsClass)
        else
            tbGoodsList = CoinShopData.GetRewardsList(tbTitle.nRewardsClass)[nSubClass]
        end
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        tbGoodsList = CoinShopData.GetShopWeapon()
    end
end

-- 商城APi
ShopCameraApi = {}
-- 商城人物旋转接口
-- 参数：是否开启人物旋转1为开启  旋转的完成一圈的时间
function ShopCameraApi.SetCamera(nRotate,nRotateTime)
    if nRotate ~= nil then
        nCameraSwitch = tonumber(nRotate)
    end
    -- 计算旋转一圈所需要的平均时间
    if nRotateTime ~= nil then
        local nSetCameraTime  = tonumber(nRotateTime)/6
        nRotateTime = nSetCameraTime
    end
end


-- 商城目录遍历
local nTitleLine = 1
ShopGood.nStart = false
ShopErgodic.nstarTime = 0
local bShopTitleFrist = false
local nShopTitleFrist = 1
function ShopErgodic.FrameUpdate()
    if not nShopTitle then
        -- 左侧栏目初始化
        ShopTitle.initialization()
        nShopTitle = true
        ShopErgodic.nstarTime = GetTickCount()
        return
    end
    -- 目录执行
    if not ShopGood.nStart then
        if GetTickCount() - ShopErgodic.nstarTime >= ShopErgodic.nTime*1000 then --间隔10000毫秒
            if not bErgodic then
                UIMgr.Open(VIEW_ID.PanelExteriorMain)
                bErgodic = true
            end
            if nTitleLine ~= #tbShopTitle+1 then
                -- 执行一级目录                
                if not bShopTitleFrist then
                    UIHelper.GetBindScript(UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain).WidgetShoppingLeft):SetContainerSelected(nTitleLine, true)
                    bShopTitleFrist = true
                    return
                end
                if tbShopTitle[nTitleLine][nShopTitleFrist][5] == nil then
                    UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain):LinkTitle(true, tbShopTitle[nTitleLine][nShopTitleFrist][1], tbShopTitle[nTitleLine][nShopTitleFrist][2], nil,nil,true)
                else
                    UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain):LinkTitle(true,tbShopTitle[nTitleLine][nShopTitleFrist][1], tbShopTitle[nTitleLine][nShopTitleFrist][2], tbShopTitle[nTitleLine][nShopTitleFrist][5])
                end
                ShopGood.nStart = true
                Timer.AddFrameCycle(ShopGood,1,function ()
                    ShopGood.FrameUpdate(tbShopTitle[nTitleLine][nShopTitleFrist][1],tbShopTitle[nTitleLine][nShopTitleFrist][2],tbShopTitle[nTitleLine][nShopTitleFrist][5])
                end)
            else
                Timer.DelAllTimer(ShopErgodic)
                print("ShopErgodic Shop")
                -- 关闭页面
                if ShopErgodic.bSwitchCount then
                    if ShopErgodic.nErgodicLine ~= ShopErgodic.nErgodicCount+1 then
                        UIMgr.Close(VIEW_ID.PanelExteriorMain)
                        Shop.Reset()
                        bErgodic = false
                        -- 启动商城遍历
                        Timer.AddFrameCycle(ShopErgodic,1,function ()
                            ShopErgodic.FrameUpdate()
                        end)
                        ShopErgodic.nErgodicLine = ShopErgodic.nErgodicLine + 1
                    else
                        bFlag=true
                    end
                else
                    bFlag=true
                end
                -- UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain):OnSelectedHome(false)
                -- -- 新品
                -- Timer.AddFrameCycle(ShopHomeGoodsTitle,1,function ()
                --     ShopHomeGoodsTitle.FrameUpdate()
                -- end)
            end
        end
    end
end

local bCamera = false
local nShopGoodtLine = 1
local nGoodsLine = 1
local nShopGoodsStartTime = 0 -- 当前商品的时间
local nGoodsTotal = 0 -- 商品总数
local nWeaponTitle = 1 -- 特殊武器目录
-- 商城商品帧函数 根据栏目来取得对应的商品
function ShopGood.FrameUpdate(nType,nClass,nSubClass)
    if not ShopGood.bGoodsExterior then
        -- 初始化商品数据
        ShopGoodinitialization(nType,nClass,nSubClass)
        -- 商品表总数
        if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            for key, value in pairs(tbGoodsList) do
                if key == "tSetList" then
                    for _, _ in pairs(value) do
                        nGoodsTotal = nGoodsTotal + 1
                    end
                end
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.ITEM  then
            if nSubClass == nil then
                for _, v in pairs(tbGoodsList[1]) do
                    if type(v) == "table" then
                        nGoodsTotal = nGoodsTotal + 1
                    end
                end
            else
                for _, v in pairs(tbGoodsList) do
                    if type(v) == "table" then
                        nGoodsTotal = nGoodsTotal + 1
                    end
                end
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            -- 特殊目录分为两个
            for _, _ in pairs(tbGoodsList[nWeaponTitle]) do
                nGoodsTotal = nGoodsTotal + 1
            end
        end
        ShopGood.bGoodsExterior = true
        return
    end
    if not bCamera then
        if GetTickCount() - nShopGoodsStartTime >= nShopGoodsTime*1000 then
            nShopGoodsStartTime = GetTickCount()
            if nGoodsLine ~= nGoodsTotal+1 then
                -- 商品表数据处理
                if nType == COIN_SHOP_GOODS_TYPE.ITEM then
                    -- 商品道具处理
                    if nSubClass == nil then
                        CoinShopUICheck(nType,nClass,nil,nil,tbGoodsList[nShopGoodtLine][nGoodsLine]["dwLogicID"])
                    else
                        CoinShopUICheck(nType,nClass,nil,nil,tbGoodsList[nGoodsLine]["dwLogicID"],nSubClass)
                    end
                elseif nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
                    CoinShopUICheck(nType,nClass,nil,tbGoodsList["tSetList"][nGoodsLine]["nSet"],nil)
                elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                    CoinShopUICheck(nType,nClass,tbGoodsList[nWeaponTitle][nGoodsLine]["dwID"],nil,nil) 
                end
                nGoodsLine  = nGoodsLine + 1
            else
                -- 武器目录
                if nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR  then
                    if nWeaponTitle ~= 2 then
                        nGoodsTotal = 0
                        nGoodsLine = 1
                        ShopGood.bGoodsExterior = false
                        nWeaponTitle = nWeaponTitle + 1
                        return
                    end
                end
                -- 结束帧函数
                nShopTitleFrist = nShopTitleFrist+1
                if nShopTitleFrist == #tbShopTitle[nTitleLine]+1 then
                    nTitleLine = nTitleLine + 1
                    nShopTitleFrist = 1
                    bShopTitleFrist = false
                end
                nGoodsTotal = 0
                nGoodsLine = 1
                ShopGood.bGoodsExterior = false
                ShopGood.nStart = false
                Timer.DelAllTimer(ShopGood)
                print("ShopGood Shop")
            end
        end
    end
end


-- 记录商城数据
-- Contents(总目录),Firstdirectory(一级目录),Secondarydirectory(二级目录),dwID,GoodType
function RecordGoods(dwID,GoodType)
    local szName,_,_,_ = CoinShop_GetGoodsName(GoodType,dwID)
    szContent=string.format("%s\t%s\t%s\t%s\t%s\n",UTF8ToGBK("商城"),tbShopTitle[nTitleLine][nShopTitleFrist][4],tbShopTitle[nTitleLine][nShopTitleFrist][3],dwID,szName)
    file:write(szContent)
    file:flush()
end

local ShopSleep = {}
ShopSleep.nstartTime = 0
ShopSleep.nNextTime = 3
-- 选中商品后再等待秒数再进行模型旋转
function ShopSleep.FrameUpdate()
    if GetTickCount()-ShopSleep.nstartTime >= ShopSleep.nNextTime*1000 then
        -- 启动人物体型旋转
        Timer.AddFrameCycle(CameraRotate,1,function ()
            CameraRotate.FrameUpdate()
        end)
        Timer.DelAllTimer(ShopSleep)
    end
end


-- 不同商品对应的商品ui不同 需要选择到对应的ui nType nClass dwID
function CoinShopUICheck(nType,nClass,dwID,nSet,tItem,nSubClass)
    -- 先进行下载
    local tbTitle = CoinShop_GetTitleInfo(nType, nClass)
    local UICoinShopMainView = UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain)
    if tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        UICoinShopMainView:LinkExteriorSet(nSet)
        if UINodeControl.BtnTrigger("BtnDownload") then
            RecordGoods(tbGoodsList["tSetList"][nGoodsLine]["tSub"][1],COIN_SHOP_GOODS_TYPE.EXTERIOR)
        end
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
        UICoinShopMainView:LinkRewardsItem(tItem)
        if UINodeControl.BtnTrigger("BtnDownload") then
            if nSubClass == nil then
                RecordGoods(tbGoodsList[nShopGoodtLine][nGoodsLine]["dwLogicID"],COIN_SHOP_GOODS_TYPE.ITEM)
            else
                RecordGoods(tbGoodsList[nGoodsLine]["dwLogicID"],COIN_SHOP_GOODS_TYPE.ITEM)
            end
        end
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        UICoinShopMainView:LinkWeapon(dwID)
        if UINodeControl.BtnTrigger("BtnDownload") then
            RecordGoods(dwID,COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR)
        end
    end
    if nCameraSwitch == 1 then
        bCamera = true
        -- 启动商品等待秒数
        ShopSleep.nstartTime = GetTickCount()
        Timer.AddFrameCycle(ShopSleep,1,function ()
            ShopSleep.FrameUpdate()
        end)
    end
end

-- 摄像机旋转一周
local nCameraX = 0
-- 摄像机旋转
function CameraRotate.FrameUpdate()
    -- 根据每帧来旋转参数
    if UITouchHelper._model ~=nil then
        if nCameraX >=6.3 then
            nCameraX = 0
            Timer.DelAllTimer(CameraRotate)
            nShopGoodsStartTime = GetTickCount()
            bCamera = false
        end
        local nGetFpS = GetHotPointReader().GetFrameDataInfo().FPS
        -- 摄像机旋转的角度
        local nCameraAngle = 6.3/nCameraTime/nGetFpS
        UITouchHelper._model:SetYaw(nCameraX)
        nCameraX = nCameraX + nCameraAngle
    end
end



local nShopHomeTitleTotal = 0 -- 限时抢购商品目录
local nShopHomeLine = 1
local tbShopHome = {}   -- 限时抢购商品
local tbShopHomeData = {}
-- 限时抢购商品初始化
function ShopHomeGoods.Initialization()
    nShopHomeTitleTotal = #CoinShopData.GetHomeList()[1].tList
    for i=1 ,nShopHomeTitleTotal do
        for _,tbShop in pairs(CoinShopData.GetRewardsList(nShopHomeLine)) do
            for key, ShopValue in pairs(tbShop) do
                if type(key) == "number" then
                    table.insert(tbShopHomeData,ShopValue)
                end
            end
            table.insert(tbShopHome,tbShopHomeData)
            tbShopHomeData = {}
        end
        nShopHomeLine = nShopHomeLine + 1
    end
end
local bShopHomeTitle = false
local nShopHomeGoods = false
local nHomeStratTime = 0
local nShopHomeGoodsTotal = 0
local nShopHomeGoodsLine = 1    -- 限时商品行数
local nShopHomeTitleLine = 1    -- 限时目录行数
-- 限时抢购商品目录遍历
function ShopHomeGoodsTitle.FrameUpdate()
    if not nShopHomeGoods then
        ShopHomeGoods.Initialization()
        nShopHomeGoods = true
        nShopHomeGoodsTotal = #tbShopHome[1]
        return
    end
    if not bShopHomeTitle then
        if nShopHomeTitleLine == nShopHomeTitleTotal + 1 then
            Timer.DelAllTimer(ShopHomeGoodsTitle)
            bFlag=true
            return
        end
        if nShopHomeTitleLine ~= 1 then
            UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain):LinkTitle(true, 6, nShopHomeTitleLine)
        end
        bShopHomeTitle = true
        Timer.AddFrameCycle(ShopHomeGoods,1,function ()
            ShopHomeGoods.FrameUpdate()
        end)
    end
end

-- 限时抢购商品遍历
function ShopHomeGoods.FrameUpdate()
    if not bCamera then 
        if GetTickCount()-nHomeStratTime>nHomeTime*1000 then
            if nShopHomeGoodsLine == nShopHomeGoodsTotal + 1 then
                Timer.DelAllTimer(ShopHomeGoods)
                bShopHomeTitle = false
                nShopHomeTitleLine = nShopHomeTitleLine + 1
                return
            end
            CoinShop_PreviewGoods(6, tbShopHome[1][nShopHomeGoodsLine].dwLogicID, true)
            nShopHomeGoodsLine = nShopHomeGoodsLine + 1
            nHomeStratTime = GetTickCount()
            if nCameraSwitch == 1 then
                bCamera = true
                -- 启动人物体型旋转
                Timer.AddFrameCycle(CameraRotate,1,function ()
                    CameraRotate.FrameUpdate()
                end)
            end
        end
    end
end

-- 重置所参数
function Shop.Reset()
    nTitleLine = 1
    ShopGood.nStart = false
    ShopErgodic.nstarTime = 0
    bShopTitleFrist = false
    nShopTitleFrist = 1
    nShopTitle = false
    tbShopTitle = {}          -- 一级目录
    tbShopTitleSecondary= {}  -- 二级目录
    bCamera = false
    nShopGoodtLine = 1
    nGoodsLine = 1
    nShopGoodsStartTime = 0 -- 当前商品的时间
    nGoodsTotal = 0 -- 商品总数
    nWeaponTitle = 1 -- 特殊武器目录
    nShopHomeTitleTotal = 0 -- 限时抢购商品目录
    nShopHomeLine = 1
    tbShopHome = {}   -- 限时抢购商品
    tbShopHomeData = {}
    bShopHomeTitle = false
    nShopHomeGoods = false
    nHomeStratTime = 0
    nShopHomeGoodsTotal = 0
    nShopHomeGoodsLine = 1    -- 限时商品行数
    nShopHomeTitleLine = 1    -- 限时目录行数
    nShopTitle = false
    tbShopTitle = {}          -- 一级目录
    tbShopTitleSecondary= {}  -- 二级目录
end

-- 前后置条件
function Shop.FrameUpdate()
    local player=GetClientPlayer()
    if not player then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    --临时处理商城无限增长的问题
    if UINodeControl and UINodeControl.tbUINodeData then
        UINodeControl.tbUINodeData={}
    end
    if bFlag and GetTickCount()-pCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        print(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        print(szCmd.."ok")
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"ShopErgodic") then
            -- 启动商城遍历
            Timer.AddFrameCycle(ShopErgodic,1,function ()
                 ShopErgodic.FrameUpdate()
            end)
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(Shop,1,function ()
    Shop.FrameUpdate()
end)