InputHelper = InputHelper or {}
local self = InputHelper





-- 锁移动
function InputHelper.LockMove(bLock)
    self.bLockMove = bLock
    Event.Dispatch(EventType.SetJoyStickEnable, not self.IsLockMove())
end

function InputHelper.IsLockMove()
    return self.bLockMove or self.bTeachLockMove
end

-- 锁镜头
function InputHelper.LockCamera(bLock)
    self.bLockCamera = bLock
end

function InputHelper.IsLockCamera()
    return self.bLockCamera or self.bTeachLockCamera
end

-- 锁键盘
function InputHelper.LockKeyBoard(bLock)
    ShortcutInteractionData.SetEnableKeyBoard(not bLock)
end

function InputHelper.IsLockKeyBoard()
    return ShortcutInteractionData.GetEnableKeyBoard()
end

-- 教学锁移动
function InputHelper.TeachLockMove(bLock)
    self.bTeachLockMove = bLock
    Event.Dispatch(EventType.SetJoyStickEnable, not self.IsLockMove())
end

-- 教学锁镜头
function InputHelper.TeachLockCamera(bLock)
    self.bTeachLockCamera = bLock
end