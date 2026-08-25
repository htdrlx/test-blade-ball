-- ================================================================
--  ZURO UI — BLADE BALL  (fixed + all kitty-lol features ported)
--  Fixes: CreateWindow now returns proper window; get_num_not found;
--         parry guard complete; kitty accurate parry algo ported
-- ================================================================

setfpscap(9999)

-- ── Services ─────────────────────────────────────────────────
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UIS            = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Lighting       = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService   = game:GetService("SoundService")
local StarterGui     = game:GetService("StarterGui")
local StatsService   = game:GetService("Stats")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- cleanup cũ
if playerGui:FindFirstChild("ZuroUI")     then playerGui.ZuroUI:Destroy() end
if playerGui:FindFirstChild("ZuroStats")  then playerGui.ZuroStats:Destroy() end
if Lighting:FindFirstChild("ZuroUIBlur")  then Lighting.ZuroUIBlur:Destroy() end

-- ── Màu / Tween constants ─────────────────────────────────────
local C = {
    bg       = Color3.fromRGB(7,  12, 19),
    card     = Color3.fromRGB(10, 18, 28),
    sidebar  = Color3.fromRGB(8,  15, 24),
    ctrl     = Color3.fromRGB(15, 30, 45),
    ctrlHov  = Color3.fromRGB(22, 46, 68),
    sel      = Color3.fromRGB(20, 48, 72),
    border   = Color3.fromRGB(50, 110,155),
    div      = Color3.fromRGB(28, 58, 82),
    accent   = Color3.fromRGB(67, 160,220),
    white    = Color3.fromRGB(225,244,255),
    text     = Color3.fromRGB(190,220,240),
    dim      = Color3.fromRGB(120,165,195),
    muted    = Color3.fromRGB(72, 115,140),
    swOff    = Color3.fromRGB(28, 48, 64),
}
local EASE = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ── UI helpers ────────────────────────────────────────────────
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent = parent; return o
end
local function rnd(o,r)  mk("UICorner",{CornerRadius=UDim.new(0,r)},o) end
local function stk(o,c,t,tr) mk("UIStroke",{Color=c or C.border,Thickness=t or 1,Transparency=tr or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o) end
local function pad(o,l,r,t,b)
    mk("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),
        PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0)},o)
end
local function tw(o,i,p) TweenService:Create(o,i or EASE,p):Play() end
local function hover(btn,n,h)
    btn.MouseEnter:Connect(function() tw(btn,FAST,{BackgroundColor3=h}) end)
    btn.MouseLeave:Connect(function() tw(btn,FAST,{BackgroundColor3=n}) end)
end

-- ── Game state ────────────────────────────────────────────────
local BallsFolder  = workspace:FindFirstChild("Balls") or workspace:WaitForChild("Balls",10)
local ballStates   = {}
local ballPrevVel  = {}
local antiCurve    = {}
local parriedBalls = {}

-- Combat flags
local AutoParry   = false
local AnimFix     = false
local AutoSpam    = false
local ManualSpam  = false
local SpamActive  = false
local CurrentMode = "None"
local ParryRange  = 100
local basePreClick = 1.4
local maxHMiss     = 5
local LastParry    = 0
local aggressiveMode    = false
local autoSpamThread    = nil
local manualSpamThread  = nil
local autoSpamRunning   = false
local manualSpamRunning = false

-- Anti-curve
local ACCURACY_FACTOR        = 1.285
local CURVE_BOOST_FACTOR     = 1.3
local CURVE_ACCEL_THRESHOLD  = 60
local SMOOTH_ALPHA           = 0.3
local CONSISTENT_FRAMES      = 3
local parryTimes = {}
local parryCount = 0
local parryHead  = 1

-- Misc flags
local trailEnabled     = false
local selectedTrail    = "Rainbow"
local espEnabled       = false
local hitSoundEnabled  = false
local musicEnabled     = false
local autoJumpEnabled  = false
local hasJumped        = false
local immortalEnabled  = false
local orbitEnabled     = false
local orbitAngle       = 0
local orbitParts       = {}
local DesyncRadius     = 40
local DesyncHeight     = 100
local desyncCF         = {}
local desyncRot        = 0

-- ── Sounds ───────────────────────────────────────────────────
local hitSounds = {
    UwU="rbxassetid://4612696038", Medal="rbxassetid://3251785210",
    Piu="rbxassetid://5152762925", Keyboard="rbxassetid://3781186340",
    Pop="rbxassetid://4919655462", Ding="rbxassetid://4590657391",
}
local musicList = {
    Believer="rbxassetid://938085077",  Stay="rbxassetid://1215385018",
    Levitating="rbxassetid://6998388895", Sunflower="rbxassetid://4962735807",
    ["Blinding Lights"]="rbxassetid://5898558677",
}
local currentHitSound = "UwU"
local musicSound = mk("Sound",{SoundId=musicList["Believer"],Volume=0.3,Looped=true},SoundService)

local function playHit(vol)
    local s = mk("Sound",{SoundId=hitSounds[currentHitSound] or hitSounds.UwU,Volume=(vol or 80)/100},SoundService)
    s:Play(); game:GetService("Debris"):AddItem(s,2)
end
task.spawn(function()
    local rem = ReplicatedStorage:WaitForChild("Remotes",5)
    if rem then
        local ps = rem:FindFirstChild("ParrySuccess")
        if ps then ps.OnClientEvent:Connect(function() if hitSoundEnabled then playHit(80) end end) end
    end
end)

-- ── GC Remote finder (fixed — inclui get_num_not) ────────────
local remote_eh, get_hash_net, get_hash_parry
local get_num_net, get_remote_not, get_key_net_time, get_num_not
local remoteReady = false

task.spawn(function()
    pcall(function()
        if type(getgc)~="function" or type(debug)~="table" then return end
        local ok, netPath = pcall(function()
            return ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
        end)
        if not ok or not netPath then return end

        local knownRemotes = {}
        for _, item in ipairs(getgc(true)) do
            if type(item) == "table" then
                for _, v in pairs(item) do
                    -- descoberta de remotes conhecidos
                    if typeof(v)=="Instance" and v:IsA("RemoteEvent") then
                        pcall(function()
                            if v:IsDescendantOf(netPath) then knownRemotes[v]=true end
                        end)
                    end
                    -- FIX: achar get_num_not (-math.huge)
                    if type(v)=="number" and v==-math.huge then
                        get_num_not = v
                    end
                end

            elseif type(item)=="function" then
                local src = debug.info(item,"s")
                if src and src:find("SwordsController") and src:find("PRY") then
                    local ups = debug.getupvalues(item)
                    local keyTbl = ups[3]
                    for _, remote in ipairs(netPath:GetDescendants()) do
                        if remote:IsA("RemoteEvent") and not knownRemotes[remote]
                            and remote.Name:sub(1,3)=="RE/" and #remote.Name>=32
                            and select(2,remote.Name:gsub("[/`:<;_=?>]",""))>=3
                            and type(ups[8])=="string" and get_remote_not==nil
                            and type(keyTbl)=="table" and type(keyTbl[1])=="table"
                        then
                            get_key_net_time = ups[4]
                            get_num_net      = keyTbl[1][keyTbl[3]]
                            get_remote_not   = remote
                            get_hash_net     = ups[8]
                            get_hash_parry   = ups[3][2]
                            remote_eh        = remote
                            remoteReady      = true
                            return
                        end
                    end
                end
            end
        end
    end)
end)

-- ── Fire Parry (fixed guard + CurrentMode override) ──────────
local function QoqkGlSl()
    if not (remote_eh and get_hash_net and get_hash_parry
         and get_key_net_time and get_num_net and get_remote_not) then
        return false
    end
    local cam  = workspace.CurrentCamera
    local char = player.Character
    if not cam or not char then return false end

    local ok, res = pcall(function()
        -- event data
        local evData = {}
        local alive = workspace:FindFirstChild("Alive")
        if alive then
            for _, e in ipairs(alive:GetChildren()) do
                if e.PrimaryPart then
                    evData[e.Name] = cam:WorldToScreenPoint(e.PrimaryPart.Position)
                end
            end
        end
        -- aim
        local aim
        if UIS.TouchEnabled and not UIS.MouseEnabled then
            local vp = cam.ViewportSize; aim = {vp.X/2, vp.Y/2}
        else aim = (function() local m=UIS:GetMouseLocation() return {m.X,m.Y} end)() end

        -- camera override por modo
        local camCF = cam.CFrame
        if CurrentMode=="Up" then
            local l=camCF.LookVector
            camCF=CFrame.new(camCF.Position,camCF.Position+Vector3.new(l.X,10,l.Z).Unit)
        elseif CurrentMode=="Backward" then
            camCF=CFrame.lookAt(camCF.Position,camCF.Position-camCF.LookVector)
        elseif CurrentMode=="Random" then
            local r=Vector3.new(math.random(-100,100)*0.01,math.random(-35,100)*0.01,math.random(-100,100)*0.01).Unit
            camCF=CFrame.new(camCF.Position,camCF.Position+r)
        elseif CurrentMode=="Side" then
            camCF=camCF*CFrame.Angles(0,math.rad(math.random(1,2)==1 and 90 or -90),0)
        end

        -- token
        local timeStr = tostring(math.floor(workspace:GetServerTimeNow()*100))
        local key = get_key_net_time(get_num_net,"TIME")
        if type(key)~="string" or #key==0 then return false end
        local token=""
        for i=1,#timeStr do
            token=token..string.char(bit32.bxor((timeStr:byte(i)+i)%256, key:byte((i-1)%#key+1)))
        end

        remote_eh:FireServer(get_hash_net,get_hash_parry,token,get_num_not,camCF,evData,aim,false)
        return true
    end)
    return ok and res==true
end

-- ── Parry Animation (kitty-lol port) ─────────────────────────
local AnimCache   = {}
local bypassCD    = false
local lastAnimT   = 0

local function getHum()
    local c=player.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
local function getParryAnim()
    local c=player.Character; if not c then return nil end
    local SwordAPI = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("SwordAPI")
    if not SwordAPI then return nil end
    local sw=c:GetAttribute("CurrentlyEquippedSword")
    if not sw then return SwordAPI.Collection.Default:FindFirstChild("GrabParry") end
    if AnimCache[sw] then return AnimCache[sw] end
    local ok,data=pcall(function() return ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(sw) end)
    if ok and type(data)=="table" then
        for _,obj in pairs(SwordAPI.Collection:GetChildren()) do
            if obj.Name==data.AnimationType then
                local a=obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab")
                if a then AnimCache[sw]=a; return a end
            end
        end
    end
    AnimCache[sw]=SwordAPI.Collection.Default:FindFirstChild("GrabParry")
    return AnimCache[sw]
end
local function playParryAnim()
    if not AnimFix then return end
    local hum=getHum(); if not hum then return end
    local anim=getParryAnim(); if not anim then return end
    for _,t in pairs(hum.Animator:GetPlayingAnimationTracks()) do
        if t.Name=="GrabParry" or t.Name=="Grab" then t.TimePosition=0; t:Stop(0.1)
        elseif t.Name=="SuccessParry" or t.Name=="Success" then t:Stop(0.1) end
    end
    hum.Animator:LoadAnimation(anim):Play(0,1,1)
end
pcall(function()
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        bypassCD=true
        local hum=getHum()
        if hum then
            for _,t in pairs(hum.Animator:GetPlayingAnimationTracks()) do
                if t.Name=="GrabParry" or t.Name=="Grab" then t:Stop(0.1) end
            end
        end
    end)
end)

-- ── Ping ─────────────────────────────────────────────────────
local pingItem
pcall(function() pingItem=StatsService.Network.ServerStatsItem["Data Ping"] end)
local function getPing()
    local ok,v=pcall(function() return pingItem:GetValue() end)
    return ok and v or 80
end

-- ── Anti-curve multiplier (kitty-lol) ────────────────────────
local function curveMult(ball, playerPos, vel)
    local prev = ballPrevVel[ball]
    if not prev then
        ballPrevVel[ball]=vel
        antiCurve[ball]={sax=0,say=0,saz=0,frames=0}
        return 1
    end
    local ax,ay,az = vel.X-prev.X, vel.Y-prev.Y, vel.Z-prev.Z
    ballPrevVel[ball]=vel
    local d = antiCurve[ball] or {sax=0,say=0,saz=0,frames=0}
    antiCurve[ball]=d
    d.sax=d.sax*(1-SMOOTH_ALPHA)+ax*SMOOTH_ALPHA
    d.say=d.say*(1-SMOOTH_ALPHA)+ay*SMOOTH_ALPHA
    d.saz=d.saz*(1-SMOOTH_ALPHA)+az*SMOOTH_ALPHA
    local aMag=math.sqrt(d.sax^2+d.say^2+d.saz^2)
    if aMag<0.1 then d.frames=0; return 1 end
    local dx=playerPos.X-ball.Position.X
    local dy=playerPos.Y-ball.Position.Y
    local dz=playerPos.Z-ball.Position.Z
    local dist=math.sqrt(dx*dx+dy*dy+dz*dz)
    if dist<0.01 then d.frames=0; return 1 end
    local radial=(d.sax*dx+d.say*dy+d.saz*dz)/dist
    local lat=math.sqrt(math.max(aMag^2-radial^2,0))
    if lat>CURVE_ACCEL_THRESHOLD and radial>0 then
        d.frames=d.frames+1
        if d.frames>=CONSISTENT_FRAMES then
            local sev=math.min(lat/(CURVE_ACCEL_THRESHOLD*2),1)
            return 1+(CURVE_BOOST_FACTOR-1)*sev
        end
    else d.frames=0 end
    return 1
end

-- ── Parry timing recorder ─────────────────────────────────────
local function recordParry()
    local now=tick()
    if parryCount<5 then parryCount=parryCount+1
    else parryHead=(parryHead%5)+1 end
    parryTimes[((parryHead+parryCount-2)%5)+1]=now
end
local function countRecent()
    local now=tick(); local n=0
    for i=1,parryCount do
        local idx=(parryHead+i-2)%5+1
        if now-(parryTimes[idx] or 0)<0.5 then n=n+1 end
    end
    return n
end

-- ── Ball state ────────────────────────────────────────────────
local function initBall(ball)
    if ball:GetAttribute("realBall") then
        ballStates[ball]={parried=false}
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if ballStates[ball] then ballStates[ball].parried=false end
        end)
    end
end
if BallsFolder then
    BallsFolder.ChildAdded:Connect(initBall)
    BallsFolder.ChildRemoved:Connect(function(b)
        ballStates[b]=nil; ballPrevVel[b]=nil; antiCurve[b]=nil
    end)
    for _,b in ipairs(BallsFolder:GetChildren()) do initBall(b) end
end

-- VLog / PLog references (set later after UI)
local VLog, PLog
local peakVel=0

-- ── Auto Parry Loop (kitty accurate algo) ────────────────────
local apConn
local function autoParryLoop()
    if not AutoParry or not BallsFolder then return end
    local char=player.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos=hrp.Position
    local pingFactor=math.clamp(getPing()*0.01,1,20)

    for _,ball in ipairs(BallsFolder:GetChildren()) do
        if not ball:GetAttribute("realBall") then continue end
        local target=ball:GetAttribute("target") or ball:GetAttribute("Target")
            or ball:GetAttribute("targetPlayer") or ball:GetAttribute("TargetPlayer")
        local mine=false
        if target then
            mine=(target==player.Name or target==player.UserId or target==tostring(player.UserId))
        else
            local d=(pos-ball.Position).Magnitude
            if d<=30 then
                local v=ball.AssemblyLinearVelocity
                if v.Magnitude>1 then mine=(pos-ball.Position).Unit:Dot(v.Unit)>0.4 end
            end
        end
        if not mine then continue end

        local st=ballStates[ball]
        if not st then initBall(ball); st=ballStates[ball] end
        if not st or st.parried then continue end

        local zoomies=ball:FindFirstChild("zoomies")
        if not zoomies then
            local d=(pos-ball.Position).Magnitude
            if d<=math.max(1,12*(ParryRange/100)) and ball.AssemblyLinearVelocity.Magnitude>1 then
                st.parried=true; QoqkGlSl(); playParryAnim(); recordParry()
                task.delay(1.5,function() if ballStates[ball] then ballStates[ball].parried=false end end)
            end
            continue
        end

        local velVec=zoomies.VectorVelocity
        local vx,vy,vz=velVec.X,velVec.Y,velVec.Z
        local dx,dy,dz=pos.X-ball.Position.X,pos.Y-ball.Position.Y,pos.Z-ball.Position.Z
        local distSq=dx*dx+dy*dy+dz*dz
        if distSq<1 then continue end
        local dist=math.sqrt(distSq)
        local approach=(dx*vx+dy*vy+dz*vz)/dist
        if approach<=0 then continue end
        local hSpSq=vx*vx+vz*vz
        if hSpSq>0.001 then
            if math.abs(dx*vz-dz*vx)/math.sqrt(hSpSq)>maxHMiss then continue end
        end
        local capped=math.min(approach,650)
        local baseR=2.4+capped*0.002
        local radius=pingFactor+math.max(approach/(baseR*ACCURACY_FACTOR),9.5)
        radius=radius*basePreClick*curveMult(ball,pos,velVec)*(ParryRange/100)

        local spd=velVec.Magnitude
        if VLog and VLog.Parent then VLog.Text=math.floor(spd)..".0" end
        if spd>peakVel then peakVel=spd; if PLog and PLog.Parent then PLog.Text=math.floor(peakVel)..".0" end end

        if dist<=radius then
            st.parried=true; QoqkGlSl(); playParryAnim(); recordParry()
            task.spawn(function()
                if target then pcall(function() ball:GetAttributeChangedSignal("target"):Wait() end)
                else task.wait(1.5) end
                if ballStates[ball] then ballStates[ball].parried=false end
            end)
        end
    end
end
RunService.Stepped:Connect(autoParryLoop)

-- ── Spam functions ────────────────────────────────────────────
local function startAutoSpam()
    if autoSpamThread then return end
    autoSpamRunning=true
    autoSpamThread=task.spawn(function()
        while autoSpamRunning do QoqkGlSl(); RunService.RenderStepped:Wait() end
        autoSpamThread=nil
    end)
end
local function stopAutoSpam() autoSpamRunning=false; autoSpamThread=nil end

local function startManualSpam()
    if manualSpamThread then return end
    manualSpamRunning=true
    manualSpamThread=task.spawn(function()
        while manualSpamRunning do QoqkGlSl(); RunService.RenderStepped:Wait() end
        manualSpamThread=nil
    end)
end
local function stopManualSpam() manualSpamRunning=false; manualSpamThread=nil end

local function checkAutoSpam()
    if not AutoSpam then
        if aggressiveMode then aggressiveMode=false; stopAutoSpam() end; return
    end
    local shouldAgg=(countRecent()>=3)
    if shouldAgg~=aggressiveMode then
        aggressiveMode=shouldAgg
        if aggressiveMode then startAutoSpam() else stopAutoSpam() end
    end
end

-- ── Trail ─────────────────────────────────────────────────────
local rainbow={
    Color3.fromRGB(255,0,0),Color3.fromRGB(255,165,0),
    Color3.fromRGB(255,255,0),Color3.fromRGB(0,255,0),
    Color3.fromRGB(0,0,255),Color3.fromRGB(255,0,255),
    Color3.fromRGB(0,255,255),Color3.fromRGB(255,105,180),
}
local colorOpts={
    Blue=Color3.fromRGB(0,120,255),Yellow=Color3.fromRGB(255,220,0),
    Green=Color3.fromRGB(0,255,100),Pink=Color3.fromRGB(255,105,180),
    Cyan=Color3.fromRGB(0,255,255),
}
local cIdx=1

local function addTrail(ball,color)
    if not ball:FindFirstChild("ZTrail") then
        local a0=mk("Attachment",{Name="ZTA0",Position=Vector3.new(0,1,0)},ball)
        local a1=mk("Attachment",{Name="ZTA1",Position=Vector3.new(0,-1,0)},ball)
        local t=mk("Trail",{Name="ZTrail",Attachment0=a0,Attachment1=a1,
            Lifetime=0.5,MinLength=0,LightEmission=0.6,
            Transparency=NumberSequence.new(0,1)},ball)
    end
    local t=ball:FindFirstChild("ZTrail")
    if t and typeof(color)=="Color3" then t.Color=ColorSequence.new(color) end
end
local function removeTrail(ball)
    for _,n in ipairs({"ZTrail","ZTA0","ZTA1"}) do
        local c=ball:FindFirstChild(n); if c then c:Destroy() end
    end
end

-- ── Orbit ─────────────────────────────────────────────────────
local function setupOrbit()
    for _,v in pairs(orbitParts) do pcall(function() v:Destroy() end) end
    orbitParts={}
    local cols={Color3.fromRGB(0,255,255),Color3.fromRGB(255,0,255),
                Color3.fromRGB(255,255,0),Color3.fromRGB(0,255,0)}
    for i=1,4 do
        local p=mk("Part",{Name="ZOrbit",Size=Vector3.new(0.5,0.5,0.5),
            Anchored=true,CanCollide=false,Color=cols[i],
            Material=Enum.Material.Neon,CastShadow=false},workspace)
        table.insert(orbitParts,p)
    end
end

-- ── Immortal (desync) ─────────────────────────────────────────
task.spawn(function()
    while true do
        if immortalEnabled then
            local c=player.Character
            local hrp=c and c:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp:SetNetworkOwner(player) end) end
        end
        task.wait()
    end
end)
RunService.Heartbeat:Connect(function()
    if not immortalEnabled then return end
    local c=player.Character
    local hrp=c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    desyncRot=(desyncRot+15)%360
    desyncCF[1]=hrp.CFrame
    desyncCF[2]=hrp.AssemblyLinearVelocity
    local spoof=hrp.CFrame*CFrame.Angles(0,math.rad(desyncRot),0)+Vector3.new(0,DesyncHeight,0)
    local hw=math.sin(tick()*30)*DesyncRadius
    local vw=math.cos(tick()*60)*DesyncHeight
    spoof=spoof*CFrame.new(hw,vw,0)
    hrp.CFrame=spoof
    hrp.AssemblyLinearVelocity=desyncCF[2]+Vector3.new(math.cos(tick()*8)*3000,math.cos(tick()*8)*3000,0)
    RunService.RenderStepped:Wait()
    if hrp and hrp.Parent then
        hrp.CFrame=desyncCF[1]
        hrp.AssemblyLinearVelocity=desyncCF[2]
    end
end)
pcall(function()
    local origIdx
    origIdx=hookmetamethod(game,"__index",newcclosure(function(self,key)
        if immortalEnabled and not checkcaller() and key=="CFrame" then
            local c=player.Character
            if c then
                local hrp=c:FindFirstChild("HumanoidRootPart")
                if hrp and self==hrp then return desyncCF[1] or CFrame.new() end
            end
        end
        return origIdx(self,key)
    end))
end)

-- ── RenderStepped: trail + ESP + autojump + orbit ─────────────
RunService.RenderStepped:Connect(function()
    cIdx=cIdx%#rainbow+1
    checkAutoSpam()

    -- Trail
    if BallsFolder then
        for _,ball in ipairs(BallsFolder:GetChildren()) do
            if ball:IsA("BasePart") then
                if trailEnabled then
                    local col = selectedTrail=="Rainbow" and rainbow[cIdx] or colorOpts[selectedTrail]
                    addTrail(ball,col)
                    if selectedTrail=="Rainbow" then
                        local t=ball:FindFirstChild("ZTrail")
                        if t then t.Color=ColorSequence.new(rainbow[cIdx]) end
                    end
                else removeTrail(ball) end
            end
        end
    end

    -- ESP
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local head=p.Character:FindFirstChild("Head")
            if head then
                local bb=head:FindFirstChild("ZuroESP")
                if espEnabled then
                    if not bb then
                        local bg=mk("BillboardGui",{Name="ZuroESP",Size=UDim2.new(0,200,0,50),
                            AlwaysOnTop=true,ExtentsOffset=Vector3.new(0,3,0)},head)
                        mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                            Text=p.DisplayName,TextColor3=Color3.new(1,1,1),
                            Font=Enum.Font.GothamBold,TextSize=18,
                            TextStrokeTransparency=0,TextStrokeColor3=Color3.new(0,0,0)},bg)
                    end
                else if bb then bb:Destroy() end end
            end
        end
    end

    -- Auto Jump
    if autoJumpEnabled and not hasJumped then
        local c=player.Character
        if c then
            local h=c:FindFirstChildOfClass("Humanoid")
            if h and h.FloorMaterial~=Enum.Material.Air then
                h.Jump=true; hasJumped=true
                task.delay(1,function() hasJumped=false end)
            end
        end
    end

    -- Orbit
    if orbitEnabled then
        orbitAngle=orbitAngle+0.05
        local c=player.Character
        local hrp=c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            if #orbitParts==0 then setupOrbit() end
            local r=4
            local offs={
                Vector3.new(math.cos(orbitAngle)*r,0,math.sin(orbitAngle)*r),
                Vector3.new(math.cos(orbitAngle+math.pi)*r,0,math.sin(orbitAngle+math.pi)*r),
                Vector3.new(0,math.sin(orbitAngle)*r,math.cos(orbitAngle)*r),
                Vector3.new(0,math.cos(orbitAngle)*r,math.sin(orbitAngle+math.pi/2)*r),
            }
            for i,part in pairs(orbitParts) do
                if part and part.Parent then part.CFrame=CFrame.new(hrp.Position+offs[i]) end
            end
        end
    elseif #orbitParts>0 then
        for _,v in pairs(orbitParts) do pcall(function() v:Destroy() end) end
        orbitParts={}
    end
end)

-- ================================================================
--  ZURO UI LIBRARY  (hoàn chỉnh — có AddTab/Section/Toggle/Slider/Button/Dropdown)
-- ================================================================

local Zuro={}; Zuro.__index=Zuro

function Zuro:CreateWindow(opts)
    opts=opts or {}

    -- ScreenGui
    local screen=mk("ScreenGui",{Name="ZuroUI",IgnoreGuiInset=true,
        ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        DisplayOrder=100},playerGui)
    mk("BlurEffect",{Name="ZuroUIBlur",Size=opts.Blur or 0},Lighting)

    -- Scale root
    local scaleRoot=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.5),
        Size=UDim2.fromOffset(960,600),
        BackgroundTransparency=1},screen)
    local scaler=mk("UIScale",{Scale=1},scaleRoot)
    local function rescale()
        local cam=workspace.CurrentCamera; if not cam then return end
        local vp=cam.ViewportSize
        scaler.Scale=math.clamp(math.min(vp.X/960,vp.Y/600)*0.82,0.38,1)
    end
    rescale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
    end

    -- Shadow
    local shad=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
        Size=UDim2.fromOffset(980,620),BackgroundColor3=Color3.new(0,0,0),
        BackgroundTransparency=.55,BorderSizePixel=0},scaleRoot)
    rnd(shad,18)

    -- Shell
    local shell=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
        Size=UDim2.fromOffset(960,600),BackgroundColor3=C.bg,BorderSizePixel=0},scaleRoot)
    rnd(shell,14); stk(shell,C.border,1.5)

    -- Header
    local header=mk("TextButton",{Size=UDim2.new(1,0,0,46),
        BackgroundColor3=Color3.fromRGB(10,20,32),
        BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=5},shell)
    rnd(header,14)
    -- cover bottom-left/right corners of header
    mk("Frame",{Position=UDim2.fromOffset(0,14),Size=UDim2.new(1,0,1,-14),
        BackgroundColor3=Color3.fromRGB(10,20,32),BorderSizePixel=0,ZIndex=4},header)
    -- divider
    mk("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),
        BackgroundColor3=C.div,BorderSizePixel=0,ZIndex=6},header)

    mk("TextLabel",{Position=UDim2.fromOffset(18,0),Size=UDim2.fromOffset(300,46),
        BackgroundTransparency=1,Text=opts.Title or "Zuro",
        TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.white,
        TextXAlignment=Enum.TextXAlignment.Left},header)

    -- Drag header
    local drag,dragStart,startPos=false
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true;dragStart=i.Position;startPos=scaleRoot.Position
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dragStart
            scaleRoot.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)

    -- Body
    local body=mk("Frame",{Position=UDim2.fromOffset(0,46),Size=UDim2.new(1,0,1,-46),
        BackgroundTransparency=1,ZIndex=6},shell)

    -- Sidebar
    local sidebar=mk("Frame",{Size=UDim2.fromOffset(192,554),
        BackgroundColor3=C.sidebar,BorderSizePixel=0},body)
    mk("Frame",{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),
        BackgroundColor3=C.div,BorderSizePixel=0},sidebar)
    local tabList=mk("Frame",{Position=UDim2.fromOffset(10,14),
        Size=UDim2.fromOffset(172,526),BackgroundTransparency=1},sidebar)
    mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},tabList)

    -- Page area
    local pageArea=mk("Frame",{Position=UDim2.fromOffset(192,0),
        Size=UDim2.new(1,-192,1,0),BackgroundTransparency=1,ClipsDescendants=true},body)

    -- Notify holder
    local notifHolder=mk("Frame",{AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-10,1,-10),Size=UDim2.fromOffset(250,0),
        BackgroundTransparency=1,ZIndex=60},shell)
    mk("UIListLayout",{Padding=UDim.new(0,5),VerticalAlignment=Enum.VerticalAlignment.Bottom,
        SortOrder=Enum.SortOrder.LayoutOrder},notifHolder)

    -- ── Window object ──────────────────────────────────────────
    local win={_cur=nil}

    function win:Notify(o)
        o=o or {}
        local f=mk("Frame",{Size=UDim2.new(1,0,0,54),BackgroundColor3=C.card,
            BorderSizePixel=0,ZIndex=61},notifHolder)
        rnd(f,8); stk(f,C.border,1,0.45)
        pad(f,12,12,8,8)
        mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
            Text=o.Title or "Zuro",TextSize=13,Font=Enum.Font.GothamBold,
            TextColor3=C.white,TextXAlignment=Enum.TextXAlignment.Left},f)
        mk("TextLabel",{Position=UDim2.fromOffset(0,18),Size=UDim2.new(1,0,0,22),
            BackgroundTransparency=1,Text=o.Content or "",TextSize=12,
            Font=Enum.Font.GothamMedium,TextColor3=C.dim,
            TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},f)
        task.delay(o.Duration or 3,function()
            tw(f,FAST,{BackgroundTransparency=1}); task.wait(0.18); f:Destroy()
        end)
    end

    function win:AddTab(name)
        -- Sidebar button
        local btn=mk("TextButton",{Size=UDim2.new(1,0,0,32),
            BackgroundColor3=C.ctrl,BackgroundTransparency=1,
            BorderSizePixel=0,Text="",AutoButtonColor=false},tabList)
        rnd(btn,7)
        mk("TextLabel",{Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-12,1,0),
            BackgroundTransparency=1,Text=name,TextSize=13,
            Font=Enum.Font.GothamMedium,TextColor3=C.muted,
            TextXAlignment=Enum.TextXAlignment.Left},btn)

        -- Page (ScrollingFrame)
        local page=mk("ScrollingFrame",{Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScrollBarThickness=3,ScrollBarImageColor3=C.border,
            CanvasSize=UDim2.fromScale(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Visible=false},pageArea)
        pad(page,14,14,14,14)
        -- Two columns inside page
        local function makeCol(xScale,xOffset)
            local col=mk("Frame",{Position=UDim2.new(xScale,xOffset,0,0),
                Size=UDim2.new(0.5,-9,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1},page)
            mk("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},col)
            return col
        end
        local colL=makeCol(0,0)
        local colR=makeCol(0.5,5)

        local tab={}
        local lbl=btn:FindFirstChildOfClass("TextLabel")

        local function activate()
            if win._cur and win._cur~=tab then
                win._cur._page.Visible=false
                tw(win._cur._btn,FAST,{BackgroundTransparency=1})
                local l=win._cur._btn:FindFirstChildOfClass("TextLabel")
                if l then tw(l,FAST,{TextColor3=C.muted}) end
            end
            win._cur=tab; page.Visible=true
            tw(btn,FAST,{BackgroundTransparency=0})
            if lbl then tw(lbl,FAST,{TextColor3=C.white}) end
        end
        btn.MouseButton1Click:Connect(activate)
        hover(btn,C.ctrl,C.ctrlHov)
        tab._btn=btn; tab._page=page; tab._activate=activate

        -- ── AddSection ──────────────────────────────────────────
        function tab:AddSection(o)
            o=o or {}
            local col=(o.Column=="Right") and colR or colL
            local card=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=C.card,BorderSizePixel=0},col)
            rnd(card,10); stk(card,C.div,1,0.3)
            pad(card,13,13,10,10)
            mk("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},card)

            if o.Title then
                local th=mk("Frame",{Size=UDim2.new(1,0,0,o.Description and 34 or 18),
                    BackgroundTransparency=1},card)
                mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
                    Text=o.Title,TextSize=12,Font=Enum.Font.GothamBold,
                    TextColor3=C.accent,TextXAlignment=Enum.TextXAlignment.Left},th)
                if o.Description then
                    mk("TextLabel",{Position=UDim2.fromOffset(0,18),Size=UDim2.new(1,0,0,14),
                        BackgroundTransparency=1,Text=o.Description,TextSize=11,
                        Font=Enum.Font.Gotham,TextColor3=C.muted,
                        TextXAlignment=Enum.TextXAlignment.Left},th)
                end
                mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.div,BorderSizePixel=0},card)
            end

            local sec={}

            -- ── AddToggle ────────────────────────────────────
            function sec:AddToggle(o2)
                local row=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1},card)
                mk("TextLabel",{Size=UDim2.new(1,-52,1,0),BackgroundTransparency=1,
                    Text=o2.Name or "",TextSize=13,Font=Enum.Font.GothamMedium,
                    TextColor3=C.text,TextXAlignment=Enum.TextXAlignment.Left},row)
                local sBtn=mk("TextButton",{AnchorPoint=Vector2.new(1,0.5),
                    Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(44,24),
                    BackgroundColor3=o2.Default and C.accent or C.swOff,
                    BorderSizePixel=0,Text="",AutoButtonColor=false},row)
                rnd(sBtn,20)
                local knob=mk("Frame",{
                    Position=o2.Default and UDim2.fromOffset(22,2) or UDim2.fromOffset(2,2),
                    Size=UDim2.fromOffset(20,20),BorderSizePixel=0,BackgroundColor3=C.white},sBtn)
                rnd(knob,20)
                local val=o2.Default==true
                local function setVal(v,silent)
                    val=v
                    tw(sBtn,EASE,{BackgroundColor3=val and C.accent or C.swOff})
                    tw(knob,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
                        {Position=val and UDim2.fromOffset(22,2) or UDim2.fromOffset(2,2)})
                    if not silent and o2.Callback then task.spawn(o2.Callback,val) end
                end
                sBtn.MouseButton1Click:Connect(function() setVal(not val) end)
                if o2.Default and o2.Callback then task.spawn(o2.Callback,val) end
                return {Set=setVal,Get=function() return val end}
            end

            -- ── AddSlider ────────────────────────────────────
            function sec:AddSlider(o2)
                local min,max=o2.Min or 0,o2.Max or 100
                local val=math.clamp(o2.Default or min,min,max)
                local hdr=mk("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1},card)
                mk("TextLabel",{Size=UDim2.new(1,-42,1,0),BackgroundTransparency=1,
                    Text=o2.Name or "",TextSize=12,Font=Enum.Font.GothamMedium,
                    TextColor3=C.dim,TextXAlignment=Enum.TextXAlignment.Left},hdr)
                local valLbl=mk("TextLabel",{AnchorPoint=Vector2.new(1,0),
                    Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(40,16),
                    BackgroundTransparency=1,Text=tostring(val),TextSize=12,
                    Font=Enum.Font.GothamMedium,TextColor3=C.accent,
                    TextXAlignment=Enum.TextXAlignment.Right},hdr)
                local slrow=mk("Frame",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,ZIndex=3},card)
                local track=mk("Frame",{AnchorPoint=Vector2.new(0,0.5),
                    Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0,5),
                    BackgroundColor3=C.div,BorderSizePixel=0},slrow)
                rnd(track,3)
                local pct=(val-min)/(max-min)
                local fill=mk("Frame",{Size=UDim2.fromScale(pct,1),
                    BackgroundColor3=C.accent,BorderSizePixel=0},track)
                rnd(fill,3)
                local knob=mk("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
                    Position=UDim2.new(pct,0,0.5,0),Size=UDim2.fromOffset(13,13),
                    BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=4},track)
                rnd(knob,7)
                local drag2=false
                local function update(px)
                    local rel=math.clamp((px-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                    val=math.floor(min+rel*(max-min))
                    fill.Size=UDim2.fromScale(rel,1)
                    knob.Position=UDim2.new(rel,0,0.5,0)
                    valLbl.Text=tostring(val)
                    if o2.Callback then o2.Callback(val) end
                end
                track.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        drag2=true; update(i.Position.X)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then drag2=false end
                end)
                UIS.InputChanged:Connect(function(i)
                    if drag2 and (i.UserInputType==Enum.UserInputType.MouseMovement
                    or i.UserInputType==Enum.UserInputType.Touch) then update(i.Position.X) end
                end)
                if o2.Callback then o2.Callback(val) end
            end

            -- ── AddButton ────────────────────────────────────
            function sec:AddButton(o2)
                local btn2=mk("TextButton",{Size=UDim2.new(1,0,0,28),
                    BackgroundColor3=C.ctrl,BorderSizePixel=0,
                    Text=o2.Name or "Button",TextSize=13,Font=Enum.Font.GothamMedium,
                    TextColor3=C.text,AutoButtonColor=false},card)
                rnd(btn2,6); stk(btn2,C.div,1,0.4)
                hover(btn2,C.ctrl,C.ctrlHov)
                btn2.MouseButton1Click:Connect(function()
                    if o2.Callback then task.spawn(o2.Callback) end
                end)
            end

            -- ── AddDropdown ──────────────────────────────────
            function sec:AddDropdown(o2)
                local vals=o2.Values or {}
                local sel=o2.Default or vals[1] or ""
                local nameRow=mk("Frame",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1},card)
                mk("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
                    Text=o2.Name or "",TextSize=11,Font=Enum.Font.Gotham,
                    TextColor3=C.muted,TextXAlignment=Enum.TextXAlignment.Left},nameRow)
                local ddRow=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,ZIndex=10},card)
                local ddBtn=mk("TextButton",{Size=UDim2.new(1,0,0,28),
                    BackgroundColor3=C.ctrl,BorderSizePixel=0,
                    Text="",AutoButtonColor=false,ZIndex=11},ddRow)
                rnd(ddBtn,6); stk(ddBtn,C.div,1,0.3)
                local ddLbl=mk("TextLabel",{Position=UDim2.fromOffset(8,0),
                    Size=UDim2.new(1,-24,1,0),BackgroundTransparency=1,
                    Text=sel,TextSize=12,Font=Enum.Font.GothamMedium,
                    TextColor3=C.text,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},ddBtn)
                mk("TextLabel",{AnchorPoint=Vector2.new(1,0.5),
                    Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(12,12),
                    BackgroundTransparency=1,Text="▾",TextSize=13,
                    Font=Enum.Font.GothamBold,TextColor3=C.dim,ZIndex=12},ddBtn)
                local listOpen=false; local listFrame
                ddBtn.MouseButton1Click:Connect(function()
                    listOpen=not listOpen
                    if listFrame then listFrame:Destroy(); listFrame=nil end
                    if not listOpen then return end
                    listFrame=mk("Frame",{Position=UDim2.new(0,0,1,2),
                        Size=UDim2.new(1,0,0,#vals*23+4),
                        BackgroundColor3=C.card,BorderSizePixel=0,ZIndex=20},ddBtn)
                    rnd(listFrame,6); stk(listFrame,C.div,1,0.3)
                    mk("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},listFrame)
                    pad(listFrame,2,2,2,2)
                    for _,v in ipairs(vals) do
                        local item=mk("TextButton",{Size=UDim2.new(1,0,0,19),
                            BackgroundColor3=v==sel and C.sel or C.card,
                            BackgroundTransparency=v==sel and 0 or 1,
                            Text=v,TextSize=12,Font=Enum.Font.GothamMedium,
                            TextColor3=C.text,BorderSizePixel=0,AutoButtonColor=false,ZIndex=21},listFrame)
                        rnd(item,4)
                        item.MouseButton1Click:Connect(function()
                            sel=v; ddLbl.Text=v; listOpen=false
                            if listFrame then listFrame:Destroy(); listFrame=nil end
                            if o2.Callback then o2.Callback(v) end
                        end)
                    end
                end)
                if o2.Callback then o2.Callback(sel) end
            end

            return sec
        end -- AddSection
        return tab
    end -- AddTab

    function win:SelectTab(tabObj)
        if tabObj and tabObj._activate then tabObj._activate() end
    end

    if opts.ToggleKey then
        UIS.InputBegan:Connect(function(i,p)
            if not p and i.KeyCode==opts.ToggleKey then shell.Visible=not shell.Visible end
        end)
    end

    return win
end

-- ================================================================
--  WINDOW + TABS
-- ================================================================

local window=Zuro:CreateWindow({Title="Zuro — Blade Ball",Blur=0,ToggleKey=Enum.KeyCode.RightShift})

-- ── MAIN ──────────────────────────────────────────────────────
local Main=window:AddTab("Main")

local Combat=Main:AddSection({Column="Left",Title="Combat",Description="Auto parry & timing"})
Combat:AddToggle({Name="Auto Parry",Default=false,Callback=function(s)
    AutoParry=s
    if not s then for _,st in pairs(ballStates) do if st then st.parried=false end end end
end})
Combat:AddToggle({Name="Animation Fix",Default=false,Callback=function(s) AnimFix=s end})
Combat:AddSlider({Name="Parry Range",Min=1,Max=100,Default=100,Callback=function(v) ParryRange=v end})
Combat:AddSlider({Name="Pre-Click Factor",Min=10,Max=30,Default=14,Callback=function(v) basePreClick=v/10 end})
Combat:AddSlider({Name="Max Horizontal Miss",Min=1,Max=20,Default=5,Callback=function(v) maxHMiss=v end})
Combat:AddButton({Name="Parry Now",Callback=function()
    if QoqkGlSl() then window:Notify({Title="Zuro",Content="Parry sent!",Duration=1.5})
    else window:Notify({Title="Zuro",Content="Remote chưa sẵn sàng...",Duration=2}) end
end})
Combat:AddButton({Name="Check Remote Status",Callback=function()
    window:Notify({Title="Zuro",Content=remoteReady and "✓ Remote ready" or "⏳ Đang tìm remote...",Duration=2.5})
end})

local Spam=Main:AddSection({Column="Right",Title="Spam",Description="Fast parry controls"})
Spam:AddToggle({Name="Auto Spam",Default=false,Callback=function(s)
    AutoSpam=s; if not s then stopAutoSpam(); aggressiveMode=false end
end})
Spam:AddToggle({Name="Manual Spam",Default=false,Callback=function(s)
    ManualSpam=s; if s then startManualSpam() else stopManualSpam() end
end})
Spam:AddButton({Name="Burst x12",Callback=function()
    task.spawn(function() for _=1,12 do QoqkGlSl(); task.wait(0.04) end end)
end})

-- ── CURVE MODE ────────────────────────────────────────────────
local CurveTab=window:AddTab("Curve Mode")

local CurveSec=CurveTab:AddSection({Column="Left",Title="Curve Mode",Description="Direction override khi parry"})
CurveSec:AddDropdown({Name="Mode",Values={"None","Up","Backward","Random","Side"},Default="None",
    Callback=function(v) CurrentMode=v end})

-- ── STATS ─────────────────────────────────────────────────────
local StatsTab=window:AddTab("Stats")
local StatsSec=StatsTab:AddSection({Column="Left",Title="Ball Stats",Description="Live velocity tracker"})

-- On-screen stats panel
local statsGui=mk("ScreenGui",{Name="ZuroStats",ResetOnSpawn=false,DisplayOrder=99},playerGui)
local statsFrame=mk("Frame",{Position=UDim2.new(0.05,0,0.38,0),Size=UDim2.fromOffset(175,108),
    BackgroundColor3=C.bg,BackgroundTransparency=0,Visible=false},statsGui)
rnd(statsFrame,12); stk(statsFrame,C.border,1.5)
pad(statsFrame,13,13,10,10)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="BALL STATS",
    TextSize=11,Font=Enum.Font.GothamBold,TextColor3=C.muted,
    TextXAlignment=Enum.TextXAlignment.Left},statsFrame)
mk("TextLabel",{Position=UDim2.fromOffset(0,19),Size=UDim2.new(1,0,0,11),
    BackgroundTransparency=1,Text="Velocity",TextSize=11,Font=Enum.Font.Gotham,
    TextColor3=C.muted,TextXAlignment=Enum.TextXAlignment.Left},statsFrame)
VLog=mk("TextLabel",{Position=UDim2.fromOffset(0,31),Size=UDim2.new(1,0,0,24),
    BackgroundTransparency=1,Text="0.0",TextSize=22,Font=Enum.Font.GothamBold,
    TextColor3=Color3.fromRGB(255,180,60),TextXAlignment=Enum.TextXAlignment.Left},statsFrame)
mk("TextLabel",{Position=UDim2.fromOffset(0,62),Size=UDim2.new(1,0,0,11),
    BackgroundTransparency=1,Text="Peak",TextSize=11,Font=Enum.Font.Gotham,
    TextColor3=C.muted,TextXAlignment=Enum.TextXAlignment.Left},statsFrame)
PLog=mk("TextLabel",{Position=UDim2.fromOffset(0,75),Size=UDim2.new(1,0,0,20),
    BackgroundTransparency=1,Text="0.0",TextSize=16,Font=Enum.Font.GothamBold,
    TextColor3=Color3.fromRGB(100,180,255),TextXAlignment=Enum.TextXAlignment.Left},statsFrame)
-- drag stats frame
do local ds,dss,dsp=false
    statsFrame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true;dss=i.Position;dsp=statsFrame.Position end
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end end)
    UIS.InputChanged:Connect(function(i)
        if ds and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dss
            statsFrame.Position=UDim2.new(dsp.X.Scale,dsp.X.Offset+d.X,dsp.Y.Scale,dsp.Y.Offset+d.Y)
        end
    end)
end

StatsSec:AddToggle({Name="Show Ball Stats",Default=false,Callback=function(s)
    statsFrame.Visible=s; peakVel=0
    if VLog then VLog.Text="0.0" end; if PLog then PLog.Text="0.0" end
end})
StatsSec:AddButton({Name="Reset Peak",Callback=function()
    peakVel=0; if PLog then PLog.Text="0.0" end
end})

-- ── MISC ──────────────────────────────────────────────────────
local MiscTab=window:AddTab("Misc")

local TrailSec=MiscTab:AddSection({Column="Left",Title="Visuals",Description="Trail & ESP"})
TrailSec:AddToggle({Name="Ball Trail",Default=false,Callback=function(s) trailEnabled=s end})
TrailSec:AddDropdown({Name="Trail Color",
    Values={"Rainbow","Blue","Yellow","Green","Pink","Cyan"},Default="Rainbow",
    Callback=function(v) selectedTrail=v end})
TrailSec:AddToggle({Name="Player ESP",Default=false,Callback=function(s)
    espEnabled=s
    if not s then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local h=p.Character:FindFirstChild("Head")
                if h then local b=h:FindFirstChild("ZuroESP"); if b then b:Destroy() end end
            end
        end
    end
end})

local SoundSec=MiscTab:AddSection({Column="Right",Title="Sounds",Description="Hit sound & music"})
SoundSec:AddToggle({Name="Hit Sound",Default=false,Callback=function(s) hitSoundEnabled=s end})
SoundSec:AddDropdown({Name="Sound Type",
    Values={"UwU","Medal","Piu","Keyboard","Pop","Ding"},Default="UwU",
    Callback=function(v) currentHitSound=v end})
SoundSec:AddToggle({Name="Background Music",Default=false,Callback=function(s)
    musicEnabled=s; if s then musicSound:Play() else musicSound:Stop() end
end})
SoundSec:AddDropdown({Name="Song",
    Values={"Believer","Stay","Levitating","Sunflower","Blinding Lights"},Default="Believer",
    Callback=function(v)
        musicSound.SoundId=musicList[v] or musicList["Believer"]
        if musicEnabled then musicSound:Stop(); musicSound:Play() end
    end})
SoundSec:AddSlider({Name="Music Volume",Min=0,Max=100,Default=30,
    Callback=function(v) musicSound.Volume=v/100 end})

-- ── PLAYER ────────────────────────────────────────────────────
local PlayerTab=window:AddTab("Player")

local MoveSec=PlayerTab:AddSection({Column="Left",Title="Movement",Description="Player modifiers"})
MoveSec:AddSlider({Name="FOV",Min=70,Max=200,Default=70,Callback=function(v)
    local cam=workspace.CurrentCamera; if cam then cam.FieldOfView=v end
end})
MoveSec:AddToggle({Name="Auto Jump",Default=false,Callback=function(s)
    autoJumpEnabled=s; hasJumped=false
end})
MoveSec:AddToggle({Name="Orbit (Around Self)",Default=false,Callback=function(s)
    orbitEnabled=s
    if not s then
        for _,v in pairs(orbitParts) do pcall(function() v:Destroy() end) end
        orbitParts={}
    end
end})

local ImmSec=PlayerTab:AddSection({Column="Right",Title="Immortal",Description="Desync-based immortality"})
ImmSec:AddToggle({Name="Immortal",Default=false,Callback=function(s)
    immortalEnabled=s; if not s then desyncCF={} end
end})
ImmSec:AddSlider({Name="Desync Radius",Min=0,Max=100,Default=40,
    Callback=function(v) DesyncRadius=v end})
ImmSec:AddSlider({Name="Desync Height",Min=0,Max=200,Default=100,
    Callback=function(v) DesyncHeight=v end})

-- ── FPS BOOST ─────────────────────────────────────────────────
local FpsTab=window:AddTab("FPS Boost")

local FpsL=FpsTab:AddSection({Column="Left",Title="Performance",Description="Render optimization"})
FpsL:AddToggle({Name="Anti Lag (Strong)",Default=false,Callback=function(s)
    pcall(function()
        settings().Rendering.QualityLevel=s and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
        Lighting.GlobalShadows=not s
        Lighting.FogEnd=s and math.huge or 100000
        Lighting.FogStart=s and math.huge or 0
        for _,v in pairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled=not s end
                if v:IsA("Texture") or v:IsA("Decal") then v.Transparency=s and 1 or 0 end
            end)
        end
    end)
end})
FpsL:AddToggle({Name="Disable Shadows",Default=false,Callback=function(s) Lighting.GlobalShadows=not s end})
FpsL:AddToggle({Name="Disable Fog",Default=false,Callback=function(s)
    Lighting.FogEnd=s and math.huge or 100000; Lighting.FogStart=s and math.huge or 0
end})
FpsL:AddToggle({Name="No Particles",Default=false,Callback=function(s)
    for _,v in pairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled=not s end
        end)
    end
end})

local FpsR=FpsTab:AddSection({Column="Right",Title="Extra",Description="More settings"})
FpsR:AddSlider({Name="Graphics Level",Min=1,Max=10,Default=10,
    Callback=function(v) pcall(function() settings().Rendering.QualityLevel=v end) end})
FpsR:AddToggle({Name="Hide Roblox UI",Default=false,Callback=function(s)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,not s)
end})
FpsR:AddToggle({Name="Disable Animations",Default=false,Callback=function(s)
    local c=player.Character
    if c then local a=c:FindFirstChild("Animate"); if a then a.Disabled=s end end
end})

-- ── Select default tab & notify ───────────────────────────────
window:SelectTab(Main)
task.wait(0.5)
window:Notify({Title="Zuro — Blade Ball",Content="Loaded! Toggle: RightShift",Duration=4})
