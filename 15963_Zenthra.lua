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

-- ================================================================
-- ZENTHRA UI LIBRARY (replaced Zuro UI; draggable mouse + touch)
-- ================================================================

local ZPlayers = game:GetService("Players")
local ZTweenService = game:GetService("TweenService")
local ZUserInputService = game:GetService("UserInputService")
local ZRunService = game:GetService("RunService")
local ZLighting = game:GetService("Lighting")
local player = ZPlayers.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("ZenthraUI") then playerGui.ZenthraUI:Destroy() end
if ZLighting:FindFirstChild("ZenthraUIBlur") then ZLighting.ZenthraUIBlur:Destroy() end
local COLORS = {
    black = Color3.fromRGB(0, 0, 0),
    card = Color3.fromRGB(4, 4, 5),
    selected = Color3.fromRGB(37, 37, 39),
    control = Color3.fromRGB(27, 26, 32),
    controlHover = Color3.fromRGB(34, 33, 40),
    border = Color3.fromRGB(79, 78, 83),
    divider = Color3.fromRGB(62, 61, 65),
    white = Color3.fromRGB(235, 234, 241),
    text = Color3.fromRGB(211, 209, 218),
    dim = Color3.fromRGB(139, 136, 147),
    muted = Color3.fromRGB(87, 85, 94),
    switchOff = Color3.fromRGB(43, 42, 51),
    switchKnob = Color3.fromRGB(117, 115, 128),
    track = Color3.fromRGB(53, 52, 60),
}
local EASE = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local DROP = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PAGE = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local MINIMIZE = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(object, pixels)
    return create("UICorner", {CornerRadius = UDim.new(0, pixels)}, object)
end
local function outline(object, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or COLORS.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, object)
end
local function padding(object, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or 0),
    }, object)
end
local function text(parent, value, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        Text = value or "", TextSize = size or 15,
        TextColor3 = color or COLORS.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end
local function tween(object, info, properties)
    local animation = ZTweenService:Create(object, info or EASE, properties)
    animation:Play()
    return animation
end
local function addHover(button, normal, hover)
    button.MouseEnter:Connect(function() tween(button, FAST, {BackgroundColor3 = hover}) end)
    button.MouseLeave:Connect(function() tween(button, FAST, {BackgroundColor3 = normal}) end)
end
local function makeLogo(parent, position)
    local logo = create("TextButton", {
        Position = position, Size = UDim2.fromOffset(34, 34),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 8,
    }, parent)
    local function line(x, y, w, h)
        create("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = COLORS.white, BorderSizePixel = 0}, logo)
    end
    line(0,0,10,2); line(0,0,2,10); line(24,0,10,2); line(32,0,2,10)
    line(0,32,10,2); line(0,24,2,10); line(24,32,10,2); line(32,24,2,10)
    return logo
end
local function makeSearch(parent, position)
    local holder = create("Frame", {Position = position, Size = UDim2.fromOffset(34,34), BackgroundTransparency = 1}, parent)
    local ring = create("Frame", {Position = UDim2.fromOffset(3,2), Size = UDim2.fromOffset(18,18), BackgroundTransparency = 1}, holder)
    round(ring, 20); outline(ring, Color3.fromRGB(205,204,211), 3, 0)
    local handle = create("Frame", {Position = UDim2.fromOffset(19,19), Size = UDim2.fromOffset(12,3), Rotation = 45, BackgroundColor3 = Color3.fromRGB(205,204,211), BorderSizePixel = 0}, holder)
    round(handle, 2)
    return holder
end
local function makeLock(parent)
    local lock = create("Frame", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-22,0,20), Size = UDim2.fromOffset(27,29), BackgroundTransparency = 1}, parent)
    local shackle = create("Frame", {Position = UDim2.fromOffset(7,1), Size = UDim2.fromOffset(14,15), BackgroundTransparency = 1}, lock)
    round(shackle, 8); outline(shackle, Color3.fromRGB(145,144,154), 2.5, 0)
    local body = create("Frame", {Position = UDim2.fromOffset(4,11), Size = UDim2.fromOffset(20,15), BackgroundColor3 = COLORS.card, BorderSizePixel = 0}, lock)
    round(body,4); outline(body, Color3.fromRGB(145,144,154), 2, 0)
    round(create("Frame", {Position = UDim2.fromOffset(12,16), Size = UDim2.fromOffset(4,7), BackgroundColor3 = Color3.fromRGB(145,144,154), BorderSizePixel = 0}, lock), 2)
    return lock
end
local function makeSlidersIcon(parent)
    local icon = create("Frame", {Size = UDim2.fromOffset(24,28), BackgroundTransparency = 1}, parent)
    for index, x in ipairs({3,11,19}) do
        create("Frame", {Position = UDim2.fromOffset(x,3), Size = UDim2.fromOffset(2,21), BackgroundColor3 = Color3.fromRGB(128,126,137), BorderSizePixel = 0}, icon)
        local y = ({7,15,10})[index]
        round(create("Frame", {Position = UDim2.fromOffset(x-2,y), Size = UDim2.fromOffset(6,5), BackgroundColor3 = Color3.fromRGB(128,126,137), BorderSizePixel = 0}, icon), 2)
    end
    return icon
end
local function makeSwitch(parent, initial, callback)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(51,28), BackgroundColor3 = initial and Color3.fromRGB(215,214,222) or COLORS.switchOff,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    }, parent)
    round(button, 20)
    local knob = create("Frame", {
        Position = initial and UDim2.fromOffset(27,3) or UDim2.fromOffset(4,3),
        Size = UDim2.fromOffset(22,22), BorderSizePixel = 0,
        BackgroundColor3 = initial and Color3.fromRGB(35,34,40) or COLORS.switchKnob,
    }, button)
    round(knob, 20)
    local value = initial == true
    local busy = false
    local function set(nextValue, silent)
        value = nextValue == true
        tween(button, EASE, {BackgroundColor3 = value and Color3.fromRGB(215,214,222) or COLORS.switchOff})
        tween(knob, TweenInfo.new(.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = value and UDim2.fromOffset(27,3) or UDim2.fromOffset(4,3),
            BackgroundColor3 = value and Color3.fromRGB(35,34,40) or COLORS.switchKnob,
        })
        if not silent and callback then task.spawn(callback, value) end
    end
    button.MouseButton1Click:Connect(function()
        if busy then return end
        busy = true; set(not value); task.delay(.1, function() busy = false end)
    end)
    local switchObject = {Instance = button, Set = set, Get = function() return value end}
    switchObject.change_state = function(_, state) return set(state) end
    return switchObject
end
local Zenthra = {}
Zenthra.__index = Zenthra
function Zenthra:CreateWindow(options)
    options = options or {}
    local screen = create("ScreenGui", {
        Name = "ZenthraUI", IgnoreGuiInset = true, ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
    }, playerGui)
    local blur = create("BlurEffect", {Name = "ZenthraUIBlur", Size = options.Blur or 0}, ZLighting)
    local scaleRoot = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(1080,680), BackgroundTransparency = 1,
    }, screen)
    local scaler = create("UIScale", {Scale = 1}, scaleRoot)
    local scaleRefreshers = {}
    local function rescale()
        local camera = workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            scaler.Scale = math.clamp(math.min(viewport.X/1080, viewport.Y/680) * .70, .30, .90)
            task.defer(function()
                for _, refresh in ipairs(scaleRefreshers) do refresh() end
            end)
        end
    end
    rescale()
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end
    local shadow = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(1100,700), BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = .48, BorderSizePixel = 0, ZIndex = 0,
    }, scaleRoot)
    round(shadow, 25)
    local shell = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(1080,680),
        BackgroundColor3 = COLORS.black, BorderSizePixel = 0, ClipsDescendants = false, ZIndex = 1,
    }, scaleRoot)
    round(shell, 18)
    local outerBorder = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = shell.Position,
        Size = shell.Size, BackgroundTransparency = 1, BorderSizePixel = 0,
        Active = false, ZIndex = 100,
    }, scaleRoot)
    round(outerBorder, 18)
    local outerStroke = outline(outerBorder, Color3.fromRGB(158,158,164), 2.5, 0)
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(205,205,209)),
            ColorSequenceKeypoint.new(.18, Color3.fromRGB(125,125,130)),
            ColorSequenceKeypoint.new(.62, Color3.fromRGB(72,72,76)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(118,118,122)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(.22, .20),
            NumberSequenceKeypoint.new(.72, .42),
            NumberSequenceKeypoint.new(1, .14),
        }),
    }, outerStroke)
    local header = create("TextButton", {
        Size = UDim2.new(1,0,0,94), BackgroundColor3 = Color3.fromRGB(74,74,76), BorderSizePixel = 0,
        Text = "", AutoButtonColor = false, ZIndex = 5,
    }, shell)
    round(header, 18)
    create("UIGradient", {Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(111,111,113)),
        ColorSequenceKeypoint.new(.28, Color3.fromRGB(65,65,67)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(25,25,27)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(4,4,5)),
    })}, header)
    local sheen = create("Frame", {
        Size = UDim2.new(1,0,0,52), BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0, BorderSizePixel = 0, Active = false,
    }, header)
    round(sheen, 18)
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, .78),
            NumberSequenceKeypoint.new(.34, .91),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, sheen)
    local logo = makeLogo(header, UDim2.fromOffset(25,22))
    local title = text(header, options.Title or "Zenthra UI", 21, Color3.fromRGB(248,248,248), true)
    title.Position = UDim2.fromOffset(70,9); title.Size = UDim2.fromOffset(210,54)
    local search = makeSearch(header, UDim2.new(1,-55,0,22))
    local body = create("CanvasGroup", {
        Position = UDim2.fromOffset(0,76), Size = UDim2.new(1,0,1,-76),
        BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 0, ZIndex = 6,
    }, shell)
    local sidebar = create("Frame", {Size = UDim2.fromOffset(270,604), BackgroundTransparency = 1}, body)
    create("Frame", {Position = UDim2.new(1,-1,0,36), Size = UDim2.new(0,1,1,-72), BackgroundColor3 = Color3.fromRGB(46,46,49), BorderSizePixel = 0}, sidebar)
    local tabHolder = create("Frame", {Position = UDim2.fromOffset(28,25), Size = UDim2.fromOffset(212,420), BackgroundTransparency = 1}, sidebar)
    create("UIListLayout", {Padding = UDim.new(0,7), SortOrder = Enum.SortOrder.LayoutOrder}, tabHolder)
    local pageArea = create("Frame", {Position = UDim2.fromOffset(270,0), Size = UDim2.new(1,-270,1,0), BackgroundTransparency = 1, ClipsDescendants = true}, body)
    local window = {
        Screen = screen, Shell = shell, Header = header, Body = body, Sidebar = sidebar,
        PageArea = pageArea, Tabs = {}, ActiveTab = nil, Minimized = false,
    }
    local DRAG_INSET = 10
    local dragHandles = {}
    local function edge(anchor, position, size)
        local handle = create("TextButton", {
            AnchorPoint = anchor, Position = position, Size = size,
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 60,
        }, shell)
        table.insert(dragHandles, handle)
        return handle
    end
    edge(Vector2.new(0,0), UDim2.fromOffset(0,0), UDim2.new(1,0,0,DRAG_INSET))
    edge(Vector2.new(0,1), UDim2.new(0,0,1,0), UDim2.new(1,0,0,DRAG_INSET))
    edge(Vector2.new(0,0), UDim2.fromOffset(0,0), UDim2.new(0,DRAG_INSET,1,0))
    edge(Vector2.new(1,0), UDim2.new(1,0,0,0), UDim2.new(0,DRAG_INSET,1,0))
    local dragging, dragStart, shellStart = false, nil, nil
    local function moveWindow(offset)
        shell.Position = shellStart + offset
        shadow.Position = shell.Position
        outerBorder.Position = shell.Position
    end
    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            shellStart = shell.Position
        end
    end
    for _, handle in ipairs(dragHandles) do
        handle.InputBegan:Connect(beginDrag)
    end
    header.InputBegan:Connect(beginDrag)
    ZUserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            moveWindow(UDim2.fromOffset(delta.X/scaler.Scale, delta.Y/scaler.Scale))
        end
    end)
    ZUserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
        end
    end)
    logo.MouseButton1Click:Connect(function()
        window:SetMinimized(not window.Minimized)
    end)
    function window:SetMinimized(state)
        if self._minimizing or self.Minimized == state then return end
        self._minimizing = true; self.Minimized = state
        if state then
            search.Visible = false
            tween(body, TweenInfo.new(.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
            task.delay(.13, function()
                if self.Minimized then body.Visible = false end
                tween(shell, MINIMIZE, {Size = UDim2.fromOffset(184,78)})
                tween(header, MINIMIZE, {Size = UDim2.new(1,0,0,78)})
                tween(outerBorder, MINIMIZE, {Size = UDim2.fromOffset(184,78)})
                tween(shadow, MINIMIZE, {Size = UDim2.fromOffset(204,98)})
            end)
        else
            body.Visible = true; body.GroupTransparency = 1
            local resize = tween(shell, MINIMIZE, {Size = UDim2.fromOffset(1080,680)})
            tween(header, MINIMIZE, {Size = UDim2.new(1,0,0,94)})
            tween(outerBorder, MINIMIZE, {Size = UDim2.fromOffset(1080,680)})
            tween(shadow, MINIMIZE, {Size = UDim2.fromOffset(1100,700)})
            resize.Completed:Connect(function()
                if not self.Minimized then
                    search.Visible = true
                    tween(body, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
                end
            end)
        end
        task.delay(.42, function() self._minimizing = false end)
    end
    function window:AddTab(name, icon)
        local tabButton = create("TextButton", {
            Size = UDim2.fromOffset(212,57), BackgroundColor3 = COLORS.selected, BackgroundTransparency = 1,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false,
        }, tabHolder)
        round(tabButton,8)
        local rail = create("Frame", {Position = UDim2.fromOffset(0,17), Size = UDim2.fromOffset(3,25), BackgroundColor3 = COLORS.white, BorderSizePixel = 0, Visible = false}, tabButton)
        round(rail,3)
        local glyphs = {grid="⌘", eye="◉", image="▧", sliders="", gear="✿"}
        local glyph = text(tabButton, glyphs[icon] or icon or "•", icon == "grid" and 24 or 21, COLORS.muted, true)
        glyph.Position = UDim2.fromOffset(17,8); glyph.Size = UDim2.fromOffset(33,41); glyph.TextXAlignment = Enum.TextXAlignment.Center
        local iconParts = {}
        if icon == "sliders" then
            local vectorIcon = create("Frame", {
                Position = UDim2.fromOffset(22,16), Size = UDim2.fromOffset(24,26),
                BackgroundTransparency = 1,
            }, tabButton)
            local knobX = {6,15,10}
            for index, y in ipairs({5,13,21}) do
                local line = create("Frame", {
                    Position = UDim2.fromOffset(1,y), Size = UDim2.fromOffset(22,2),
                    BackgroundColor3 = COLORS.muted, BorderSizePixel = 0,
                }, vectorIcon)
                round(line,2); table.insert(iconParts,line)
                local knob = create("Frame", {
                    Position = UDim2.fromOffset(knobX[index],y-2), Size = UDim2.fromOffset(5,6),
                    BackgroundColor3 = COLORS.muted, BorderSizePixel = 0,
                }, vectorIcon)
                round(knob,2); table.insert(iconParts,knob)
            end
        end
        local caption = text(tabButton, name, 16, COLORS.dim, true)
        caption.Position = UDim2.fromOffset(58,8); caption.Size = UDim2.fromOffset(140,41)
        local page = create("CanvasGroup", {
            Position = UDim2.fromOffset(24,25), Size = UDim2.new(1,-47,1,-25),
            BackgroundTransparency = 1, GroupTransparency = 1, Visible = false,
        }, pageArea)
        local columns = create("Frame", {Size = UDim2.new(1,-10,1,0), BackgroundTransparency = 1}, page)
        local left = create("ScrollingFrame", {
            Size = UDim2.new(.5,-11,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 6, ScrollBarImageColor3 = Color3.fromRGB(207,206,214),
            ScrollBarImageTransparency = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0,0), ElasticBehavior = Enum.ElasticBehavior.Always,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, columns)
        local right = create("ScrollingFrame", {
            Position = UDim2.new(.5,11,0,0), Size = UDim2.new(.5,-11,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 6, ScrollBarImageColor3 = Color3.fromRGB(207,206,214),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0,0),
            ElasticBehavior = Enum.ElasticBehavior.Always, ScrollingDirection = Enum.ScrollingDirection.Y,
        }, columns)
        for _, column in ipairs({left,right}) do
            padding(column,3,14,3,27)
            create("UIListLayout", {Padding = UDim.new(0,14), SortOrder = Enum.SortOrder.LayoutOrder}, column)
        end
        local tab = {Name=name, Button=tabButton, Rail=rail, Glyph=glyph, IconParts=iconParts, Caption=caption, Page=page, Left=left, Right=right, Sections=0, Window=window}
        table.insert(window.Tabs, tab)
        function window:SelectTab(selected)
            if self.ActiveTab == selected then return end
            local previous = self.ActiveTab
            self.ActiveTab = selected
            for _, item in ipairs(self.Tabs) do
                local active = item == selected
                tween(item.Button, PAGE, {BackgroundTransparency = active and 0 or 1})
                tween(item.Glyph, PAGE, {TextColor3 = active and COLORS.white or COLORS.muted})
                for _, iconPart in ipairs(item.IconParts or {}) do
                    tween(iconPart, PAGE, {BackgroundColor3 = active and COLORS.white or COLORS.muted})
                end
                tween(item.Caption, PAGE, {TextColor3 = active and COLORS.white or COLORS.dim})
                item.Rail.Visible = active
            end
            if previous then
                tween(previous.Page, TweenInfo.new(.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1, Position = UDim2.fromOffset(14,25)})
                task.delay(.12, function() if self.ActiveTab ~= previous then previous.Page.Visible = false end end)
            end
            selected.Page.Visible = true; selected.Page.GroupTransparency = 1; selected.Page.Position = UDim2.fromOffset(34,25)
            tween(selected.Page, PAGE, {GroupTransparency = 0, Position = UDim2.fromOffset(24,25)})
        end
        tabButton.MouseButton1Click:Connect(function() window:SelectTab(tab) end)
        if not window.ActiveTab then window:SelectTab(tab) end
        function tab:AddSection(config)
            config = config or {}
            if self == nil then error("AddSection: tab is nil (AddTab failed)", 2) end
            self.Sections = (self.Sections or 0) + 1
            local target = config.Column == "Right" and self.Right or (config.Column == "Left" and self.Left or (self.Sections%2 == 0 and self.Right or self.Left))
            local section = create("Frame", {
                Size = UDim2.new(1,0,0,154), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = COLORS.card, BorderSizePixel = 0, ClipsDescendants = true,
            }, target)
            round(section,15); outline(section, COLORS.border, 1.5, .05)
            local headerPart = create("Frame", {Size = UDim2.new(1,0,0,95), BackgroundTransparency = 1}, section)
            local sectionTitle = text(headerPart, config.Title or "Section", 16, COLORS.white, true)
            sectionTitle.Position = UDim2.fromOffset(22,14); sectionTitle.Size = UDim2.new(1,-72,0,28)
            local description = text(headerPart, config.Description or "Example section", 13, COLORS.dim, false)
            description.Position = UDim2.fromOffset(22,45); description.Size = UDim2.new(1,-46,0,24)
            makeLock(headerPart)
            local master = create("Frame", {Position = UDim2.fromOffset(0,95), Size = UDim2.new(1,0,0,57), BackgroundTransparency = 1}, section)
            create("Frame", {Size = UDim2.new(1,0,0,1), BackgroundColor3 = COLORS.divider, BorderSizePixel = 0}, master)
            local masterIcon = makeSlidersIcon(master)
            masterIcon.Position = UDim2.fromOffset(25,14)
            local itemsClip = create("CanvasGroup", {
                Position = UDim2.fromOffset(0,152), Size = UDim2.new(1,0,0,0),
                BackgroundTransparency = 1, ClipsDescendants = true, GroupTransparency = 0,
            }, section)
            local items = create("Frame", {
                Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
            }, itemsClip)
            local itemsLayout = create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, items)
            local sectionExpanded = config.Enabled ~= false
            local sectionTransition = 0
            local function contentHeight()
                return math.max(0, itemsLayout.AbsoluteContentSize.Y / math.max(scaler.Scale, 0.01))
            end
            local function setSectionExpanded(state, instant)
                sectionExpanded = state == true
                sectionTransition += 1
                local transitionId = sectionTransition
                itemsClip.Visible = true
                if sectionExpanded then
                    local targetHeight = contentHeight()
                    if instant then
                        itemsClip.Size = UDim2.new(1,0,0,targetHeight)
                        itemsClip.GroupTransparency = 0
                    else
                        tween(itemsClip, DROP, {
                            Size = UDim2.new(1,0,0,targetHeight),
                            GroupTransparency = 0,
                        })
                    end
                else
                    if instant then
                        itemsClip.Size = UDim2.new(1,0,0,0)
                        itemsClip.GroupTransparency = 1
                        itemsClip.Visible = false
                    else
                        tween(itemsClip, DROP, {
                            Size = UDim2.new(1,0,0,0),
                            GroupTransparency = 1,
                        })
                        task.delay(DROP.Time, function()
                            if transitionId == sectionTransition and not sectionExpanded then
                                itemsClip.Visible = false
                            end
                        end)
                    end
                end
            end
            local masterSwitch = makeSwitch(master, sectionExpanded, function(state)
                setSectionExpanded(state, false)
                if config.Callback then task.spawn(config.Callback, state) end
            end)
            masterSwitch.Instance.AnchorPoint = Vector2.new(1,.5)
            masterSwitch.Instance.Position = UDim2.new(1,-20,.5,0)
            local function refreshSectionHeight()
                if sectionExpanded then
                    itemsClip.Size = UDim2.new(1,0,0,contentHeight())
                end
            end
            itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshSectionHeight)
            table.insert(scaleRefreshers, refreshSectionHeight)
            setSectionExpanded(sectionExpanded, true)
            local sectionObject = {
                Instance=section, Items=items, Master=masterSwitch,
                SetExpanded=function(_,state) masterSwitch.Set(state) end,
                IsExpanded=function() return sectionExpanded end,
            }
            function sectionObject:AddToggle(data)
                data = data or {}
                local row = create("Frame", {Size = UDim2.new(1,0,0,47), BackgroundTransparency = 1}, items)
                local caption = text(row, data.Name or "Toggle", 15, COLORS.text, true)
                caption.Position = UDim2.fromOffset(27,4); caption.Size = UDim2.new(1,-110,1,-8)
                local control = makeSwitch(row, data.Default == true, data.Callback)
                control.Instance.AnchorPoint=Vector2.new(1,.5); control.Instance.Position=UDim2.new(1,-20,.5,0)
                return control
            end
            function sectionObject:AddButton(data)
                data = data or {}
                local row = create("Frame", {Size=UDim2.new(1,0,0,54), BackgroundTransparency=1}, items)
                local button = create("TextButton", {Position=UDim2.fromOffset(22,6), Size=UDim2.new(1,-44,0,41), BackgroundColor3=COLORS.control, BorderSizePixel=0, Text=data.Name or "Example Button", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.text, AutoButtonColor=false}, row)
                round(button,8); outline(button,Color3.fromRGB(58,57,65),1,0); addHover(button,COLORS.control,COLORS.controlHover)
                button.MouseButton1Down:Connect(function() tween(button,FAST,{Size=UDim2.new(1,-50,0,38),Position=UDim2.fromOffset(25,8)}) end)
                button.MouseButton1Up:Connect(function() tween(button,FAST,{Size=UDim2.new(1,-44,0,41),Position=UDim2.fromOffset(22,6)}); if data.Callback then task.spawn(data.Callback) end end)
                return button
            end
            function sectionObject:AddDropdown(data)
                data = data or {}; local options = data.Options or data.Values or {"Camera","Backwards","Dot","Slow","High","Left","Right"}
                local closedHeight, optionHeight = 83, 34
                local holder = create("Frame", {Size=UDim2.new(1,0,0,closedHeight), BackgroundTransparency=1, ClipsDescendants=true}, items)
                local caption = text(holder,data.Name or "Dropdown",13,COLORS.dim,false)
                caption.Position=UDim2.fromOffset(25,5); caption.Size=UDim2.new(1,-50,0,27)
                local dropdownBackground = create("Frame", {
                    Position=UDim2.fromOffset(21,34), Size=UDim2.new(1,-42,0,48),
                    BackgroundColor3=COLORS.control, BorderSizePixel=0,
                }, holder)
                round(dropdownBackground,9); outline(dropdownBackground,Color3.fromRGB(57,56,65),1,0)
                local box = create("TextButton", {Position=UDim2.fromOffset(21,34), Size=UDim2.new(1,-42,0,48), BackgroundTransparency=1, BorderSizePixel=0, Text="", AutoButtonColor=false}, holder)
                local chosen = text(box,data.Default or options[1] or "None",13,COLORS.text,true)
                chosen.Position=UDim2.fromOffset(17,0); chosen.Size=UDim2.new(1,-50,0,48)
                local arrow = create("Frame", {
                    AnchorPoint=Vector2.new(.5,.5), Position=UDim2.new(1,-20,0,24),
                    Size=UDim2.fromOffset(18,18), BackgroundTransparency=1,
                }, box)
                local arrowLeft = create("Frame", {
                    AnchorPoint=Vector2.new(1,.5), Position=UDim2.fromOffset(9,9),
                    Size=UDim2.fromOffset(8,2), Rotation=38,
                    BackgroundColor3=COLORS.muted, BorderSizePixel=0,
                }, arrow)
                round(arrowLeft,2)
                local arrowRight = create("Frame", {
                    AnchorPoint=Vector2.new(0,.5), Position=UDim2.fromOffset(9,9),
                    Size=UDim2.fromOffset(8,2), Rotation=-38,
                    BackgroundColor3=COLORS.muted, BorderSizePixel=0,
                }, arrow)
                round(arrowRight,2)
                local menu = create("Frame", {Position=UDim2.fromOffset(21,82), Size=UDim2.new(1,-42,0,#options*optionHeight+8), BackgroundTransparency=1, BorderSizePixel=0}, holder)
                padding(menu,0,0,4,4); create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},menu)
                local open=false
                local function setOpen(state)
                    open=state; tween(arrow,DROP,{Rotation=open and 180 or 0})
                    tween(holder,DROP,{Size=UDim2.new(1,0,0,open and (closedHeight+#options*optionHeight+8) or closedHeight)})
                    tween(dropdownBackground,DROP,{Size=UDim2.new(1,-42,0,open and (56+#options*optionHeight) or 48)})
                    tween(menu,DROP,{Position=open and UDim2.fromOffset(21,82) or UDim2.fromOffset(21,70)})
                end
                box.MouseButton1Click:Connect(function() setOpen(not open) end)
                for _,option in ipairs(options) do
                    local optionButton=create("TextButton",{Size=UDim2.new(1,0,0,optionHeight),BackgroundTransparency=1,Text=option,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=COLORS.dim,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},menu)
                    padding(optionButton,17,0,0,0)
                    optionButton.MouseEnter:Connect(function() tween(optionButton,FAST,{TextColor3=COLORS.white,BackgroundTransparency=.88}) end)
                    optionButton.MouseLeave:Connect(function() tween(optionButton,FAST,{TextColor3=COLORS.dim,BackgroundTransparency=1}) end)
                    optionButton.MouseButton1Click:Connect(function() chosen.Text=option; setOpen(false); if data.Callback then task.spawn(data.Callback,option) end end)
                end
                local dropdownObject = {SetOpen=setOpen, Get=function() return chosen.Text end}
                dropdownObject.update = function(_, v) return dropdownObject:Set(v) end
                function dropdownObject:Set(value, silent)
                    chosen.Text = tostring(value)
                    if not silent and data.Callback then task.spawn(data.Callback, chosen.Text) end
                end
                return dropdownObject
            end
            function sectionObject:AddInput(data)
                data = data or {}
                local row = create("Frame", {Size=UDim2.new(1,0,0,83), BackgroundTransparency=1}, items)
                local caption = text(row, data.Name or "Input", 13, COLORS.dim, false)
                caption.Position = UDim2.fromOffset(25,5); caption.Size = UDim2.new(1,-50,0,27)
                local field = create("Frame", {
                    Position=UDim2.fromOffset(21,34), Size=UDim2.new(1,-42,0,48),
                    BackgroundColor3=COLORS.control, BorderSizePixel=0,
                }, row)
                round(field,9); outline(field,Color3.fromRGB(57,56,65),1,0)
                local box = create("TextBox", {
                    Position=UDim2.fromOffset(38,34), Size=UDim2.new(1,-76,0,48),
                    BackgroundTransparency=1, BorderSizePixel=0,
                    Text=tostring(data.Default or ""), PlaceholderText=data.Placeholder or "",
                    Font=Enum.Font.GothamBold, TextSize=13, TextColor3=COLORS.text,
                    PlaceholderColor3=COLORS.muted, TextXAlignment=Enum.TextXAlignment.Left,
                    ClearTextOnFocus=false,
                }, row)
                box.FocusLost:Connect(function(enter)
                    if data.Callback then task.spawn(data.Callback, box.Text, enter) end
                end)
                local inputObject = {Instance=box, Get=function() return box.Text end}
                inputObject.update = function(_, v) return inputObject:Set(v) end
                function inputObject:Set(value)
                    box.Text = tostring(value)
                end
                return inputObject
            end
            function sectionObject:AddSlider(data)
                data=data or {}; local minimum=data.Min or 0; local maximum=data.Max or 100
                local quant=math.max(1, 10^(data.Decimals or 0))
                local function snap(v) return math.floor(v*quant+.5)/quant end
                local current=snap(math.clamp(data.Default or maximum,minimum,maximum))
                local row=create("Frame",{Size=UDim2.new(1,0,0,75),BackgroundTransparency=1},items)
                local caption=text(row,data.Name or "Slider",15,COLORS.text,true); caption.Position=UDim2.fromOffset(27,4); caption.Size=UDim2.new(1,-110,0,30)
                local valueText=text(row,tostring(current),13,COLORS.dim,false); valueText.Position=UDim2.new(1,-75,0,4); valueText.Size=UDim2.fromOffset(50,30); valueText.TextXAlignment=Enum.TextXAlignment.Right
                local track=create("Frame",{Position=UDim2.fromOffset(28,51),Size=UDim2.new(1,-56,0,8),BackgroundColor3=COLORS.track,BorderSizePixel=0},row); round(track,8)
                local pct=(current-minimum)/(maximum-minimum)
                local fill=create("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=Color3.fromRGB(207,206,215),BorderSizePixel=0},track); round(fill,8)
                local knob=create("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(pct,0,.5,0),Size=UDim2.fromOffset(17,17),BackgroundColor3=Color3.fromRGB(232,231,238),BorderSizePixel=0},track); round(knob,20)
                local hit=create("TextButton",{Position=UDim2.fromOffset(-4,-13),Size=UDim2.new(1,8,0,34),BackgroundTransparency=1,Text="",ZIndex=4},track)
                local dragging=false
                local function update(input,smooth)
                    local p=math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1); current=snap(minimum+(maximum-minimum)*p); valueText.Text=tostring(current)
                    tween(fill,smooth and EASE or FAST,{Size=UDim2.new(p,0,1,0)}); tween(knob,smooth and EASE or FAST,{Position=UDim2.new(p,0,.5,0)})
                    if data.Callback then task.spawn(data.Callback,current) end
                end
                hit.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; update(input,true) end end)
                ZUserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then update(input,false) end end)
                ZUserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
                local sliderObject={Get=function() return current end}
                function sliderObject:Set(value, silent)
                    current=snap(math.clamp(tonumber(value) or current,minimum,maximum))
                    local p=(current-minimum)/(maximum-minimum)
                    valueText.Text=tostring(current)
                    tween(fill,FAST,{Size=UDim2.new(p,0,1,0)})
                    tween(knob,FAST,{Position=UDim2.new(p,0,.5,0)})
                    if not silent and data.Callback then task.spawn(data.Callback,current) end
                end
                return sliderObject
            end
            function sectionObject:AddRangeSlider(data)
                data=data or {}; local minimum=data.Min or 1; local maximum=data.Max or 100
                local low=math.clamp(data.Low or 14,minimum,maximum); local high=math.clamp(data.High or 100,low,maximum)
                local row=create("Frame",{Size=UDim2.new(1,0,0,86),BackgroundTransparency=1},items)
                local caption=text(row,data.Name or "Range",15,COLORS.text,true); caption.Position=UDim2.fromOffset(27,4); caption.Size=UDim2.new(1,-140,0,32)
                local values=text(row,low.." - "..high,13,COLORS.dim,false); values.Position=UDim2.new(1,-113,0,4); values.Size=UDim2.fromOffset(88,32); values.TextXAlignment=Enum.TextXAlignment.Right
                local track=create("Frame",{Position=UDim2.fromOffset(28,62),Size=UDim2.new(1,-56,0,8),BackgroundColor3=COLORS.track,BorderSizePixel=0},row); round(track,8)
                local function percent(v) return (v-minimum)/(maximum-minimum) end
                local fill=create("Frame",{Position=UDim2.new(percent(low),0,0,0),Size=UDim2.new(percent(high)-percent(low),0,1,0),BackgroundColor3=Color3.fromRGB(203,202,212),BorderSizePixel=0},track); round(fill,8)
                local lowKnob=create("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(percent(low),0,.5,0),Size=UDim2.fromOffset(17,17),BackgroundColor3=Color3.fromRGB(232,231,238),BorderSizePixel=0},track); round(lowKnob,20)
                local highKnob=create("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(percent(high),0,.5,0),Size=UDim2.fromOffset(17,17),BackgroundColor3=Color3.fromRGB(232,231,238),BorderSizePixel=0},track); round(highKnob,20)
                local hit=create("TextButton",{Position=UDim2.fromOffset(-5,-13),Size=UDim2.new(1,10,0,34),BackgroundTransparency=1,Text="",ZIndex=4},track)
                local dragging=nil
                local function redraw(info)
                    local lp,hp=percent(low),percent(high); values.Text=low.." - "..high
                    tween(lowKnob,info,{Position=UDim2.new(lp,0,.5,0)}); tween(highKnob,info,{Position=UDim2.new(hp,0,.5,0)}); tween(fill,info,{Position=UDim2.new(lp,0,0,0),Size=UDim2.new(hp-lp,0,1,0)})
                    if data.Callback then task.spawn(data.Callback,low,high) end
                end
                local function update(input,info)
                    local p=math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1); local v=math.floor(minimum+(maximum-minimum)*p+.5)
                    if dragging=="low" then low=math.min(v,high) else high=math.max(v,low) end; redraw(info)
                end
                hit.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then local p=math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1); local v=minimum+(maximum-minimum)*p; dragging=math.abs(v-low)<=math.abs(v-high) and "low" or "high"; update(input,EASE) end end)
                ZUserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then update(input,FAST) end end)
                ZUserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=nil end end)
                return {Get=function() return low,high end}
            end
            function sectionObject:SetEnabled(state, silent)
                masterSwitch.Set(state, silent ~= false)
                setSectionExpanded(state == true, false)
            end
            function sectionObject:change_state(state)
                return sectionObject:SetEnabled(state)
            end
            function sectionObject:GetEnabled()
                return masterSwitch.Get()
            end
            return sectionObject
        end
        return tab
    end
    ZUserInputService.InputBegan:Connect(function(input,processed)
        if not processed and input.KeyCode==(options.ToggleKey or Enum.KeyCode.RightShift) then
            shell.Visible=not shell.Visible
            shadow.Visible=shell.Visible
            outerBorder.Visible=shell.Visible
            blur.Enabled=shell.Visible
        end
    end)
    local toastHolder = create("Frame", {
        AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-18,1,-18),
        Size = UDim2.fromOffset(300,1), BackgroundTransparency = 1, ZIndex = 50,
    }, screen)
    create("UIListLayout", {
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder,
    }, toastHolder)
    function window:Notify(config)
        config = config or {}
        local card = create("Frame", {
            Size = UDim2.fromOffset(300,64), BackgroundColor3 = COLORS.card,
            BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 50,
        }, toastHolder)
        round(card,12); outline(card, COLORS.border, 1.5, .35)
        local heading = text(card, config.Title or "notification", 14, COLORS.white, true)
        heading.Position = UDim2.fromOffset(16,10); heading.Size = UDim2.new(1,-32,0,20)
        heading.ZIndex = 51
        local body = text(card, config.Content or "", 12, COLORS.dim, false)
        body.Position = UDim2.fromOffset(16,32); body.Size = UDim2.new(1,-32,0,22)
        body.ZIndex = 51
        tween(card, EASE, {BackgroundTransparency = 0})
        task.delay(config.Duration or 3, function()
            tween(card, EASE, {BackgroundTransparency = 1})
            for _, child in ipairs(card:GetDescendants()) do
                if child:IsA("TextLabel") then tween(child, EASE, {TextTransparency = 1}) end
                if child:IsA("UIStroke") then tween(child, EASE, {Transparency = 1}) end
            end
            task.delay(EASE.Time + .05, function() card:Destroy() end)
        end)
        return card
    end
    screen.Destroying:Connect(function() if blur and blur.Parent then blur:Destroy() end end)

--  WINDOW + TABS
-- ================================================================

local window=Zuro:CreateWindow({Title="Zenthra — Blade Ball",Blur=0,ToggleKey=Enum.KeyCode.RightShift})

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
    if QoqkGlSl() then window:Notify({Title="Zenthra",Content="Parry sent!",Duration=1.5})
    else window:Notify({Title="Zenthra",Content="Remote chưa sẵn sàng...",Duration=2}) end
end})
Combat:AddButton({Name="Check Remote Status",Callback=function()
    window:Notify({Title="Zenthra",Content=remoteReady and "✓ Remote ready" or "⏳ Đang tìm remote...",Duration=2.5})
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
        if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then
            ds=true; dss=i.Position; dsp=statsFrame.Position
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then ds=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if ds and (i.UserInputType==Enum.UserInputType.MouseMovement
            or i.UserInputType==Enum.UserInputType.Touch) then
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
window:Notify({Title="Zenthra — Blade Ball",Content="Loaded! Toggle: RightShift",Duration=4})
