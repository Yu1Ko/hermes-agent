-- 目录 商城商品名称
local szHead="Contents\tGoodName\n"
local szGoodsFilePath=SearchPanel.szCurrentInterfacePath.."ShopRunMap.tab"
local file=io.open(szGoodsFilePath,"w")
file:write(szHead)

Randomstore = {}
local ShopTimerCount = 0 -- 限时商品栏
local ShoplimitCount = 0 -- 限量商品栏
local bFlag = true
-- 初始化商品
function RandomStoreInit()
    for key, _ in pairs(CoinShopData.GetRewardsList(1)[1]) do 
        if type(key) == "number" then
            ShopTimerCount = ShopTimerCount + 1
        end
    end
    for key, _ in pairs(CoinShopData.GetRewardsList(2)[1]) do 
        if type(key) == "number" then
            ShoplimitCount = ShoplimitCount + 1
        end
    end
end

-- 实时写入商品
function RecordGoods(contents,dwID)
    local szName,_,_,_ = CoinShop_GetGoodsName(6,dwID)
    local szContents
    if contents == 1 then
        szContents = "限时"
    end
    if contents == 2 then
        szContents = "限量"
    end
    local szContent = string.format("%s\t%s\n",UTF8ToGBK(szContents),szName)
    file:write(szContent)
    file:flush()
end


-- 随机商品数
function GetRandomShop(contents)
    local ShopLine = 0 -- 商品位置
    if contents == 1 then
        ShopLine = math.random(1, ShopTimerCount)
    end
    if contents == 2 then
        ShopLine = math.random(1, ShoplimitCount)
    end
    return ShopLine
end
Randomstore.nNextTime = 1 -- 每一秒选中一次商品
Randomstore.Count = 200 --默认为200次
Randomstore.Line = 1
Randomstore.nCurrentTime =0
function Randomstore.FrameUpdate()
    if GetTickCount()-Randomstore.nCurrentTime>Randomstore.nNextTime*1000 then
        -- 随机选中一个栏目
        local nShopContents = math.random(1, 2)
        UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain):LinkTitle(true, 6, nShopContents)
        -- 取出商品
        local nShopLine = GetRandomShop(nShopContents)
        -- 写入商品
        RecordGoods(nShopContents,CoinShopData.GetRewardsList(nShopContents)[1][nShopLine].dwLogicID)
        -- 选中商品
        CoinShop_PreviewGoods(6, CoinShopData.GetRewardsList(nShopContents)[1][nShopLine].dwLogicID, true)
        Randomstore.Line = Randomstore.Line + 1
        Randomstore.nCurrentTime = GetTickCount()
    end
end


--读取tab的内容 
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local nCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1
RunMap={}

function RunMap.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"RandomShop") then
            RandomStoreInit()
            Timer.AddFrameCycle(Randomstore,1,function ()
                Randomstore.FrameUpdate()
            end)
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)