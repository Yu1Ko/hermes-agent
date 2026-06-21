Version = {}

local szVersionEx = select(4, GetVersion())


-- 体服版本
function Version.IsEXP()
    return szVersionEx == "exp"
end

-- 体服PC版本
function Version.IsEXP_PC()
    return szVersionEx == "exp" and Platform.IsWindows()
end

-- iOS提审版本
function Version.IsIOS()
    return szVersionEx == "ios"
end

-- 对外正式版本（13号开的分支这个就是17号的付费测试版本）
function Version.IsMB()
    return szVersionEx == "mb"
end

-- 日常开发BVT版本
function Version.IsBVT()
    return szVersionEx == "bvt"
end

-- 抖音提审包
function Version.IsDouyin()
    return szVersionEx == "douyin"
end

-- 所有Android预发布包
function Version.IsYFB()
    return szVersionEx == "yfb"
end

-- 蔚领云提审包
function Version.IsWLCloud()
    return szVersionEx == "wlcloud"
end
