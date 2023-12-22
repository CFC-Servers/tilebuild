TOOL.Category		= "Construction"
TOOL.Name			= "Tile Build"

TOOL.ClientConVar["material"] = ""
TOOL.ClientConVar["red"] = 255
TOOL.ClientConVar["green"] = 255
TOOL.ClientConVar["blue"] = 255
TOOL.ClientConVar["alpha"] = 255
TOOL.ClientConVar["proptype"] = "models/squad/sf_plates/sf_plate4x4.mdl"
TOOL.ClientConVar["guide"] = "1"
TOOL.ClientConVar["dynamicsnap"] = "0"
TOOL.ClientConVar["snapdivision"] = "1"
TOOL.ClientConVar["previewbox"] = "1"
TOOL.ClientConVar["outline"] = "1"
--add sprops plates pt 2

--fix snapdivisor with no dynamic snap display

-- this is what i use to get data on props, if you want to suffer through adding your own stuff for some reason these are the tools you need.


-- converts a prop to data on spawn.

if SERVER then

    util.AddNetworkString("tilebuild_snapnoise")
    util.AddNetworkString("tilebuild_rightclick")
    CreateConVar("tilebuild_searchspeed", "4", FCVAR_ARCHIVE, "how many ticks to wait between searching the prop table, may reduce lag if encountered", 1, 100 )

end

CreateConVar("tilebuild_sprops", "0", FCVAR_ARCHIVE, "enable or disable sprops showing in the tilebuild menu, requires restart", 0, 1 )

if CLIENT then

    TOOL.Information = {
        {name = "left", stage = 0},
        {name = "right", stage = 0},
        {name = "left2", stage = 1},
        {name = "reload", stage = 1},
    }

    language.Add("tool.tilebuild.name", "Tile Build")
    language.Add("tool.tilebuild.desc", "Creates a prop based on specified dimensions.")

    language.Add("tool.tilebuild.left", "Select minimum bounds.")
    language.Add("tool.tilebuild.right", "Drag prop.")
    language.Add("tool.tilebuild.left2", "Select maximum bounds.")
    language.Add("tool.tilebuild.reload", "Cancel prop placement.")

end


--[[hook.Add( "OnEntityCreated", "logproptb", function( ent )

    if false then

    timer.Simple(.01, function()

    if not IsValid(ent:GetPhysicsObject()) or ent:IsPlayer() then return end

    if SERVER then

    local min, max = ent:GetPhysicsObject():GetAABB()
    local tempdim = max - min
    local dimensions = max - min
    local angle = Angle(0,0,0)
    local roundedx, roundedy, roundedz = math.Round(dimensions.x, 0), math.Round(dimensions.y, 0), math.Round(dimensions.z, 0)

    if roundedy > roundedx and not (roundedz > roundedy) then

        angle = Angle(0, -90, 0)

    end

    if roundedz > roundedx then

        angle = angle + Angle((-angle.y * 2) + 90, 0, 0)

    end

    min:Rotate(angle)
    max:Rotate(angle)


    if not IsValid(ent) then return end

        print(

            "{'" .. ent:GetModel() .. "', " ..
            "Vector(" .. tostring(min.x) .. "," .. tostring(min.y) .. "," .. tostring(min.z)  .. "), " ..
            "Vector(" .. tostring(max.x) .. "," .. tostring(max.y) .. "," .. tostring(max.z)  .. "), " ..
            "Angle(" .. tostring(angle.p) .. "," .. tostring(angle.y) .. "," .. tostring(angle.r) .. ")},"

        )


        ent:Remove()

    end

    end)

    end

end)]]

--[[ second tool: splits the table into "bubbles" for optimization:

-- run this anywhere, i made my own file and just ran this seperate with copy and pasted data from above tool.
local newtable = {}

local nums = {}

local largest = 500 -- this is the largest prop in your prop type's dimensions aka (max - min):Length()

local guh = 0 -- this is to get the above.

local nuba = 25 -- this is the "bubble increment". fiddle with this until the tables printed into console are "equally" filled aka you have 10-ish tables and each has around 50 props in it or so.

for i = 0, largest, nuba do

    nums[i] = 0
    newtable[i] = {}

end

-- replace table here V with a table full of data gotten from above hook.
for k, v in pairs(sprops) do

    local dim = v[3] - v[2]

    nums[math.SnapTo(dim:Length(), nuba)] = nums[math.SnapTo(dim:Length(), nuba)] + 1

    table.insert(newtable[math.SnapTo(dim:Length(), nuba)], v)

    if dim:Length() > guh then guh = dim:Length() end

end

-- you might have to make this file yourself in garrysmod/data, idk ive never used it before :)
file.Write("testoutput.txt", table.ToString(newtable, "sprops", true))

--proptable data goes ["name"] = {does nothing lol, does nothing lmao, actual table, i think this also does nothing now, the snap of the grid aka the unit scale of your prop }]

]]


local sharedsnap = 11.859375

local platetable = {

    ["superflat"] = {1, 2, TILEBUILD.tilebuild_superflat, 0, 12},
    ["steel"] = {1, 2, TILEBUILD.tilebuild_steel, 0, sharedsnap},
    ["plastic"] = {1, 2, TILEBUILD.tilebuild_plastic, 0, sharedsnap},
    ["steelframe"] = {1, 2, TILEBUILD.tilebuild_steelframe, 0, sharedsnap},
    ["wood"] = {1, 2, TILEBUILD.tilebuild_wood, 0, sharedsnap},
    ["woodframe"] = {1, 2, TILEBUILD.tilebuild_woodframe, 0, sharedsnap},
    ["glass"] = {1, 2, TILEBUILD.tilebuild_glass, 0, sharedsnap},
    ["strongglass"] = {1, 2, TILEBUILD.tilebuild_strongglass, 0, sharedsnap},
    ["sprops"] = {1, 2, TILEBUILD.tilebuild_sprops, 1, 6},
    ["floatyplastic"] = {1, 2, TILEBUILD.tilebuild_floatyplastic, 0, sharedsnap},
    ["spropsp1"] = {1, 2, TILEBUILD.tilebuild_spropsp1, 0, 6},
    ["spropsp2"] = {1, 2, TILEBUILD.tilebuild_spropsp2, 0, 6}

}

local constructmat = Material("gm_construct/color_room")

function TOOL:Reload()
    local ply = self:GetOwner()

    if not ply.tilebuild_active or CLIENT then return end

    ply:SetNW2Bool("tilebuild_active", false)
    ply.tilebuild_active = false

    if IsValid(ply.tilebuild_prop) then ply.tilebuild_prop:Remove() end

    self:SetStage(0)
end

local function findclosestcorner(ent, pos)

    local min, max = ent:GetPhysicsObject():GetAABB()

    local localhitpos = ent:WorldToLocal(pos)

    local corners = {
        Vector(min),
        Vector(min.x, min.y, max.z),
        Vector(min.x, max.y, max.z),
        Vector(min.x, max.y, min.z),
        Vector(max),
        Vector(max.x, max.y, min.z),
        Vector(max.x, min.y, min.z),
        Vector(max.x, min.y, max.z),
    }

    local dist = math.huge
    local closestcorner = Vector(0,0,0)

    for k, v in ipairs(corners) do

        if v:Distance(localhitpos) < dist then

            dist = v:Distance(localhitpos)

            closestcorner = v

        end

    end

    closestcorner:Rotate(ent:GetAngles())

    return closestcorner + ent:GetPos()
end

local function tbmakeprop(ply, model, color, pos, angle, mat)

    model = model or "models/props_junk/watermelon01_chunk02c.mdl"
    angle = angle or Angle(0,0,0)
    mat = mat or ""

    ply.tilebuild_prop = ents.Create("prop_physics")
    ply.tilebuild_prop:SetModel(model)
    ply.tilebuild_prop:SetPos(pos)
    ply.tilebuild_prop:SetAngles(angle)
    ply.tilebuild_prop:Spawn()
    ply.tilebuild_prop:SetRenderMode(1)
    ply.tilebuild_prop:SetColor(color)
    ply.tilebuild_prop:SetMaterial(mat)
    if CPPI_DEFER ~= nil then ply.tilebuild_prop:CPPISetOwner(ply) end
    if not (color.a < 255) then ply.tilebuild_prop:SetRenderMode( 0 ) end
    ply.tilebuild_prop:GetPhysicsObject():EnableMotion(false)

    local data = { Color = color, RenderMode = ply.tilebuild_prop:GetRenderMode(), RenderFX = 0 }

    duplicator.StoreEntityModifier( ply.tilebuild_prop, "colour", data )


    ply:AddCount("props", ply.tilebuild_prop)

    cleanup.Add(ply, "props", ply.tilebuild_prop)

    undo.Create("prop")
         undo.AddEntity(ply.tilebuild_prop)
         undo.SetPlayer(ply)
     undo.Finish()
 end


function TOOL:LeftClick(tr)

    local ply = self:GetOwner()

    ply.tilebuild_currentproptype = platetable[tostring(self:GetClientInfo("proptype"))] or platetable["plastic"]

    if not ply:GetNW2Bool("tilebuild_active") then

        if not ply:CheckLimit("props") then return end

        self:SetStage(1)

        local color = Color(self:GetClientInfo("red"), self:GetClientInfo("green"), self:GetClientInfo("blue"), self:GetClientInfo("alpha"))

        local hitpos = ply:GetEyeTrace().HitPos

        local snapamount = ply.tilebuild_currentproptype[5]
        ply:SetNW2Float("tilebuild_snapamount", snapamount)

        local div = self:GetClientNumber("snapdivision")

        ply.tilebuild_startpos = Vector(math.SnapTo(hitpos.x, snapamount / div), math.SnapTo(hitpos.y, snapamount / div), math.SnapTo(hitpos.z, snapamount / div))
        tr.HitPos = ply.tilebuild_startpos
        ply.tilebuild_dist = hitpos:Distance(ply:EyePos())
        ply:SetNW2Float("tilebuild_dist", ply.tilebuild_dist)
        ply:SetNW2Vector("tilebuild_startpos", hitpos)
        ply.tilebuild_lastpos = Vector(math.huge, math.huge, math.huge)

        if SERVER then

            tbmakeprop(ply, nil, color, ply:GetPos() + Vector(0, 0, 100), Angle(0,0,0))
            ply:SetNW2Int("tilebuild_prop", ply.tilebuild_prop:EntIndex())

        end

        if self:GetClientNumber("dynamicsnap") == 1 then

            if ply:GetEyeTrace().Entity:GetClass() == "prop_physics" then

                ply.tilebuild_startpos = ply.tilebuild_dynamicsnappos

            else

                ply.tilebuild_startpos = ply:GetEyeTrace().HitPos

            end

        end

    else

        if IsValid(ply.tilebuild_prop) and SERVER then

            local fixpos = ply.tilebuild_startpos - findclosestcorner(ply.tilebuild_prop, ply.tilebuild_startpos)

            local model = ply.tilebuild_prop:GetModel()
            local pos = ply.tilebuild_prop:GetPos()
            local color = ply.tilebuild_prop:GetColor()
            local angle = ply.tilebuild_prop:GetAngles()
            local material = ply.tilebuild_prop:GetMaterial()

            ply.tilebuild_prop:Remove()

            tbmakeprop(ply, model, color, pos + fixpos, angle, material)

        end

        tr.HitPos = ply:GetNW2Vector("tilebuild_raypos")
        self:SetStage(0)

    end

    ply.tilebuild_active = not ply:GetNW2Bool("tilebuild_active")
    ply:SetNW2Bool("tilebuild_active", ply.tilebuild_active)

    return true


end

function TOOL:RightClick()

    --[[if CLIENT then

        net.Start("tilebuild_rightclick")
        net.SendToServer()

    else

        if game.SinglePlayer() then

            serverrightclick(Entity(1))

        end

    end]]

end

function tbsnaptogrid(ent, ply)

    if CLIENT then return end

    if CPPI_DEFER ~= nil then

        if ent:CPPIGetOwner() ~= ply then return end

    end

    for i = 0, 2 do

        local min, max = ent:GetPhysicsObject():GetAABB()

        local tool = ply:GetTool('tilebuild')

        currentproptype = platetable[tostring(tool:GetClientInfo("proptype"))] or platetable["plastic"]

        if ent:GetClass() == "prop_physics" and ent:GetColor() ~= Color(0, 255, 0) then

            local newangle = ent:GetAngles():SnapTo( "p", 90 ):SnapTo( "y", 90 ):SnapTo( "r", 90 )

            local minlocation = min
            minlocation:Rotate( ent:GetAngles() )
            minlocation = minlocation + ent:GetPos()

            local snapfixamount = currentproptype[5]

            local minsnapfixpoint = Vector(math.SnapTo(minlocation.x,  snapfixamount), math.SnapTo(minlocation.y,  snapfixamount), math.SnapTo(minlocation.z,  snapfixamount))

            local dir = (minsnapfixpoint - minlocation)

            ent:SetPos(ent:GetPos() + (minsnapfixpoint - minlocation))

            ent:SetAngles(newangle)

            ent:GetPhysicsObject():EnableMotion(false)

        end

    end

end

local function getdragmove(pos, snapdist, prop, proppos)

    local offset = offset or prop:GetPos()

    local pos = WorldToLocal( pos, game.GetWorld():GetAngles(), proppos, prop:GetAngles())


    local movecounts = Vector(math.Round(pos.x / snapdist, 0), math.Round(pos.y / snapdist, 0), math.Round(pos.z / snapdist, 0))
    --local move = prop:LocalToWorld(movecounts) - prop:GetPos()
    local localmove = movecounts
    movecounts:Rotate(prop:GetAngles())

    return movecounts, localmove

end

local function getpropdirscale(prop, dir)

    local dir = dir:GetNormalized()
    local forward = prop:GetForward()
    local up = prop:GetUp()
    local right = prop:GetRight()
    local min, max = prop:GetPhysicsObject():GetAABB()

    local length = nil

    if dir:IsEqualTol(up, .01) or dir:IsEqualTol(-up, .01) then
        length = max.z - min.z
    end
    if dir:IsEqualTol(right, .01) or dir:IsEqualTol(-right, .01) then
        length = max.y - min.y
    end
    if dir:IsEqualTol(forward, .01) or dir:IsEqualTol(-forward, .01) then
        length = max.x - min.x
    end

    return length

end

local function rightclickdrag(ply, dynamic)

    if ply.tilebuild_active or not ply:KeyDown(IN_ATTACK2) and engine.TickCount() % 5 == 0 then ply.tilebuild_dragoffset = nil return end

    if CPPI_DEFER ~= nil then

        if ent:CPPIGetOwner() ~= ply then return end

    end

    local tr = ply:GetEyeTrace()

    if ply:KeyPressed(IN_ATTACK2) then

        if not dynamic then tbsnaptogrid(tr.Entity, ply) end

        ply.tilebuild_prop = tr.Entity
        ply.tilebuild_dist = tr.StartPos:Distance(tr.HitPos)
        ply.tilebuild_startpos = tr.HitPos
        ply.tilebuild_dragoffset = tr.HitPos - tr.Entity:GetPos()
        ply:SetNW2Int("tilebuild_prop", tr.Entity:EntIndex())

        if not tr.Entity.tilebuild_dragstart then tr.Entity.tilebuild_dragstart = tr.Entity:GetPos() end

    end

    if SERVER and IsValid(ply.tilebuild_prop) then

        if ply.tilebuild_prop:GetClass() ~= "prop_physics" or ply.tilebuild_dragoffset == nil then return end

        local cursor = (tr.Normal * ply.tilebuild_dist) + ply:EyePos() - ply.tilebuild_dragoffset
        local snapdist = ply.tilebuild_currentproptype[5] or 0

        local move, localmove = getdragmove(cursor, snapdist, ply.tilebuild_prop, ply.tilebuild_prop:GetPos())

        local totalmove = move * snapdist

        local scale = getpropdirscale(ply.tilebuild_prop, move) or snapdist

        if (ply.tilebuild_prop:GetPos() - ply.tilebuild_prop.tilebuild_dragstart):Length() > snapdist then
            local m = getdragmove(cursor, snapdist, ply.tilebuild_prop, ply.tilebuild_prop.tilebuild_dragstart)
            totalmove = m * snapdist +  ply.tilebuild_prop.tilebuild_dragstart - ply.tilebuild_prop:GetPos()
            ply.tilebuild_prop.tilebuild_dragstart = ply.tilebuild_prop:GetPos() + totalmove
        else

            if scale < totalmove:Length() then
                totalmove = move * scale
            end

        end

        ply.tilebuild_startpos = cursor

        ply.tilebuild_prop:SetPos(ply.tilebuild_prop:GetPos() + totalmove )

        ply.tilebuild_prop:GetPhysicsObject():EnableMotion(false)

    end

end

local function getclosestkey(tbl, value)

    local closest = math.huge

    for k, v in pairs(tbl) do

        if math.abs(k - value) < math.abs(closest - value) then closest = k end

    end

    return closest

end
local noAABB = Vector(0,0,0), Vector(0,0,0)
function TOOL:Think()

    local ply = self:GetOwner()

    ply.tilebuild_tool = self

    if not ply:GetEyeTrace().Hit then return end

    if not ply:GetNW2Bool("tilebuild_deployed") then

        ply:SetNW2Bool("tilebuild_deployed", true)

    end

    local currentproptype = ply.tilebuild_currentproptype or platetable["plastic"]

    local tr = ply:GetEyeTrace()

    local hitpos = tr.HitPos

    local targetprop = nil

    if not ply.tilebuild_active then

        ply.tilebuild_targetprop = tr.Entity

        if not ply:GetNW2Bool("tilebuild_active") then

            ply:SetNW2Int("tilebuild_targetprop", ply.tilebuild_targetprop:EntIndex())

        end

    end

    rightclickdrag(ply, self:GetClientNumber("dynamicsnap") == 1)

    if CLIENT then return end

    if not IsValid(ply.tilebuild_prop) and ply.tilebuild_active then

        ply.tilebuild_active = false
        ply:SetNW2Bool("tilebuild_active", false)

    end

    --start of Dynamic Point Snapping


    targetprop = ply.tilebuild_targetprop

    local snapamount = (currentproptype[5] / self:GetClientNumber("snapdivision"))

    local startpos = ply.tilebuild_startpos

    local center = targetprop:WorldSpaceCenter()

    local diffmin, diffmax = noAABB

    if targetprop ~= game.GetWorld() then
        local min, max = targetprop:GetPhysicsObject():GetAABB()
        diffmin = min
        diffmax = max
    end

    ply.tilebuild_targetprop = targetprop

    local rawcorner = diffmin

    local div = self:GetClientNumber("snapdivision")

    if self:GetClientNumber("dynamicsnap") == 1 then

        if targetprop == game.GetWorld() or not diffmax then

            ply.tilebuild_dynamicsnappos = hitpos

        else

            snapamount = snapamount or 0
            if hitpos:Distance(ply.tilebuild_dynamicsnappos) > snapamount / 2 then

                if hitpos:Distance(center + targetprop:GetUp()) > hitpos:Distance(center + targetprop:GetUp() * -1) then
                    local stepstone = diffmin
                    diffmin = diffmax
                    rawcorner = diffmax
                    diffmax = stepstone
                end

                local diff = diffmax - diffmin

                local testcorner = targetprop:GetPhysicsObject():GetAABB()
                testcorner:Rotate(targetprop:GetAngles())
                testcorner = testcorner + targetprop:GetPos()

                local xlen = math.Max(math.Round(math.abs(diff.x) / snapamount, 0), 1)
                local ylen = math.Max(math.Round(math.abs(diff.y) / snapamount, 0), 1)
                local zlen = math.Max(math.Round(math.abs(diff.z) / snapamount, 0), 1)

                local newhitpos = WorldToLocal(hitpos, Angle(0,0,0), testcorner, targetprop:GetAngles())

                local xedgesnappos = Entity(0):GetForward() * math.SnapTo(newhitpos.x, diff.x / xlen)
                local yedgesnappos = Entity(0):GetRight()  * -math.SnapTo(newhitpos.y, diff.y / ylen)
                local zedgesnappos = Entity(0):GetUp() * math.SnapTo(newhitpos.z, diff.z / zlen)

                local finaltestgridpos = (xedgesnappos + yedgesnappos + zedgesnappos)
                finaltestgridpos:Rotate(targetprop:GetAngles())

                ply.tilebuild_dynamicsnappos = finaltestgridpos + testcorner

            end

        end

    else

        ply.tilebuild_dynamicsnappos = Vector(math.SnapTo(hitpos.x, snapamount / div), math.SnapTo(hitpos.y, snapamount / div), math.SnapTo(hitpos.z, snapamount / div))

    end

    ply:SetNW2Vector("tilebuild_dynamicsnappos", ply.tilebuild_dynamicsnappos)

    --end of Dynamic Point Snapping


    if ply.tilebuild_active then


        --start of endpos stuff

        local endpos = (ply:GetAimVector() * ply.tilebuild_dist + ply:EyePos())
            endpos = endpos + (targetprop:GetPos() - startpos)
            endpos = targetprop:WorldToLocal(endpos) + startpos


        --end of endpos stuff


        --start of Prop Angling

        local angle = Angle(0,0,0)

        local xline = Vector(endpos.x,startpos.y,startpos.z)
        local yline = Vector(startpos.x,endpos.y,startpos.z)
        local zline = Vector(startpos.x,startpos.y,endpos.z)


        local hitnormal = ply:GetEyeTrace().HitNormal

        local snappednormal = Entity(0):GetForward()
        snappednormal:Rotate(hitnormal:Angle():SnapTo( "p", 90 ):SnapTo( "y", 90 ):SnapTo( "r", 90 ))
        snappednormal = Vector(math.Round(snappednormal.x, 1), math.Round(snappednormal.y, 1), math.Round(snappednormal.z, 1))

        local linetable = {
            {xline, xline:Distance(startpos), "x"},
            {yline, yline:Distance(startpos), "y"},
            {zline, zline:Distance(startpos), "z"}
        }

        table.sort( linetable, function(a, b) return a[2] > b[2] end )

        --this is stupid and ill probably forget to make this less stupid :)
        local firstpriority = 1

        local secondpriority = 2

        local longvector = (linetable[firstpriority][1] - startpos):GetNormalized()

        local longangle = longvector:Angle()

        longangle = Angle(longangle.x, longangle.y, longangle.z)


        local holovector = Vector(0, 50, 0):GetNormalized()

        holovector:Rotate(longangle)


        local shortvector = (linetable[secondpriority][1] - startpos):GetNormalized()

        local shortangle = shortvector:AngleEx(longvector)

        local flip = math.Round(math.abs(longvector.x) + math.abs(longvector.y) + longvector.z, 0)


        local rotation = Angle(0, 0, (shortangle - holovector:AngleEx(holovector)).y * flip)


        local finalrotation = longangle + rotation

        --end of Prop Angling


        --start of prop inversion check

        local displacepointer = Vector(0, 0, 1)
        displacepointer:Rotate(finalrotation)

        local spherepos = Vector(0,0,0)

        local thirdline = (linetable[3][1] - startpos):GetNormalized() * -1

        --local displacestr = string.gsub(tostring(displacepointer), "-0", "0")
        --local thirdlinestr = string.gsub(tostring(thirdline), "-0", "0")

        local invert = thirdline:IsEqualTol(displacepointer, .01)

        if thirdline:IsEqualTol(displacepointer, .01) then
            invert = true
        end

        --end of prop inversion check


        --start of prop search

        local mcenter = Vector(0, 0, 0)
        local finalinversion = Vector(0, 0, 0)
        local cornerfix = Vector(0,0,0)
        local anglefix = Angle(0,0,0)
        local proptable = currentproptype[3]
        local bubbleinc = currentproptype[1]
        local snapnoise = Vector(0,0,0)

        if ply.tilebuild_lastpos:Distance(endpos) > 3 and ((engine.TickCount() % GetConVar("tilebuild_searchspeed"):GetFloat()) == 0) then

            proptable = proptable[getclosestkey(proptable, math.SnapTo((startpos - endpos):Length(), snapamount))]

            ply.tilebuild_lastpos = endpos


            local cursordistance = math.huge

            local lastmodel = ply.tilebuild_finalmodel

            local test = Vector(0,0,1)


            for k, v in ipairs(proptable) do

                local inversion = Vector(0,0,0)

                if invert then

                    inversion = Vector(((linetable[3][1] - startpos):GetNormalized()) * -(v[2].z - v[3].z))

                end

                local max = Vector(v[3].x, v[3].y, v[3].z)

                if v[4].y ~= 0 and v[4].p == 0 then

                    max = Vector(v[3].x, v[3].y + ((v[2].y - v[3].y) * 2), v[3].z)

                end

                if v[4].y == 0 and v[4].p > 0 then

                    max = Vector(v[3].x, v[3].y, v[3].z + ((v[2].z - v[3].z) * 2))

                    inversion = inversion * -1

                end

                max:Rotate(finalrotation)

                local tempcornerfix = Vector(v[2].x, v[2].y, v[2].z)
                tempcornerfix:Rotate(finalrotation)

                local currentmax = max + startpos - tempcornerfix + (inversion * 2)

                if endpos:Distance(currentmax) < cursordistance then

                    cursordistance = endpos:Distance(currentmax)

                    ply.tilebuild_finalmodel = v[1]

                    anglefix = v[4]

                    cornerfix = Vector(v[2].x, v[2].y, v[2].z)
                    cornerfix:Rotate(finalrotation)

                    finalinversion = inversion

                    mcenter = (currentmax + startpos) / 2


                end

            end

            --end

            local color = Color(self:GetClientInfo("red"), self:GetClientInfo("green"), self:GetClientInfo("blue"), self:GetClientInfo("alpha"))
            local material = self:GetClientInfo("material")

            local preproppos = ply.tilebuild_prop:WorldSpaceCenter()

            ply.tilebuild_prop:SetModel(ply.tilebuild_finalmodel)
            ply.tilebuild_prop:PhysicsInit(SOLID_VPHYSICS)

            local imins, imaxs = ply.tilebuild_prop:GetPhysicsObject():GetAABB()

            local physobj = ply.tilebuild_prop:GetPhysicsObject()

            ply.tilebuild_prop:SetAngles(finalrotation)
            ply.tilebuild_prop:SetAngles(physobj:RotateAroundAxis(ply.tilebuild_prop:GetUp(), anglefix.y))
            ply.tilebuild_prop:SetAngles(physobj:RotateAroundAxis(ply.tilebuild_prop:GetRight(), anglefix.p))

            if material ~= "No_Material" then ply.tilebuild_prop:SetMaterial(material) end
            ply.tilebuild_prop:SetCollisionGroup(10)

            local preangle = targetprop:GetAngles()

            targetprop:SetAngles(Angle(0,0,0))
            ply.tilebuild_prop:SetPos(targetprop:GetPos() - cornerfix + finalinversion)
            ply.tilebuild_prop:SetParent(targetprop)
            targetprop:SetAngles(preangle)
            ply.tilebuild_prop:SetParent(nil)

            mcenter = mcenter - startpos
            mcenter:Rotate(targetprop:GetAngles())
            if ply:GetNW2Vector("tilebuild_raypos") ~= (mcenter * 2) + startpos then ply:SetNW2Vector("tilebuild_raypos", (mcenter * 2) + startpos) end
            mcenter = mcenter + startpos

            ply.tilebuild_prop:SetPos(mcenter - (ply.tilebuild_prop:WorldSpaceCenter() - ply.tilebuild_prop:GetPos()))

            physobj:EnableMotion(false)

            if ply.tilebuild_prop:WorldSpaceCenter():Distance(preproppos) > 1 then

                net.Start("tilebuild_snapnoise")
                net.Send(ply)

            end

        end

        --end of prop search


    end


end

net.Receive("tilebuild_snapnoise", function()

    LocalPlayer():EmitSound("buttons/lightswitch2.wav", 75, 100, .2)

end)

function TOOL:Deploy()

    self:GetOwner():SetNW2Bool("tilebuild_deployed", true)

end

function TOOL:Holster()

    if IsValid(self:GetOwner().tilebuild_prop) and self:GetOwner():GetNW2Bool("tilebuild_active") and SERVER then
        self:GetOwner().tilebuild_prop:Remove()
    end

    self:GetOwner():SetNW2Bool("tilebuild_deployed", false)

end


hook.Add("PlayerDroppedWeapon", "tilebuild_dropped", function(ply, wep)

    if wep:GetClass() ~= "gmod_tool" then return end

    if wep:GetMode() ~= "tilebuild" then return end

    ply:SetNW2Bool("tilebuild_deployed", false)

end)

local novec = Vector(0,0,0)
local transwhite = Color( 255, 255, 255, 40)

hook.Add("PostDrawTranslucentRenderables", "tilebuildclienteffects", function(bdepth, bskybox)

    local ply = LocalPlayer()

    local tool = LocalPlayer():GetTool("tilebuild")

    if not IsValid(ply:GetActiveWeapon()) or ply:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end

    if tool == nil or ply:GetActiveWeapon():GetMode() ~= "tilebuild" or ply:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end

    --render.DrawSphere(ply:GetNW2Vector("debugmax-"), 1, 10, 10, Color( 255, 0,0 ))
    --render.DrawSphere(ply:GetNW2Vector("debugmax-2"), 1, 10, 10, Color( 0, 0,255 ))

    if not ply:GetNW2Bool("tilebuild_deployed") then return end

    --if tool:GetClientNumber("guide") == 1 then

        local tr = LocalPlayer():GetEyeTrace()

        render.SetMaterial(constructmat)

        local snapamount = ply:GetNW2Float("tilebuild_snapamount")

        local clendpos = (ply:GetAimVector() * ply:GetNW2Float("tilebuild_dist") + ply:EyePos())

        local targetprop = Entity(ply:GetNW2Int("tilebuild_targetprop"))

        local tilebuildprop = Entity(ply:GetNW2Int("tilebuild_prop"))

        local startpos = ply.tilebuild_clstartpos or novec

        if not IsValid(targetprop) and not targetprop:IsWorld() then return end

        local trueendpos = clendpos + (targetprop:GetPos() - startpos)
            trueendpos = targetprop:WorldToLocal(trueendpos) + startpos

        local active = ply:GetNW2Bool("tilebuild_active")

        local div = tool:GetClientNumber("snapdivision")


        if active then

            if (ply.tilebuild_hitent:GetClass() ~= "prop_physics") then ply.tilebuild_clstartpos = ply:GetNW2Vector("tilebuild_startpos") end

            if tool:GetClientNumber("dynamicsnap") == 0 then
                ply.tilebuild_clstartpos = Vector(
                    math.SnapTo(ply.tilebuild_clstartpos.x, snapamount / div),
                    math.SnapTo(ply.tilebuild_clstartpos.y, snapamount / div),
                    math.SnapTo(ply.tilebuild_clstartpos.z, snapamount / div)
                )
            end

            if tool:GetClientNumber("previewbox") == 1 then

                render.DrawWireframeBox(ply.tilebuild_clstartpos, targetprop:GetAngles(), novec, trueendpos - ply.tilebuild_clstartpos, color_white)

            end

            if tool:GetClientNumber("guide") == 1 then

                render.DrawSphere(clendpos, 1, 10, 10, transwhite)
                render.DrawLine(ply.tilebuild_clstartpos, clendpos, transwhite)

            end


            if IsValid(tilebuildprop) and tool:GetClientNumber("outline") == 1 then

                local min, max = tilebuildprop:GetCollisionBounds()
                render.DrawWireframeBox(tilebuildprop:GetPos(), tilebuildprop:GetAngles(), min, max, color_white)

            end


        else

            if ply.tilebuild_dragoffset ~= nil and tool:GetClientNumber("outline") == 1 then
                local min, max = tilebuildprop:GetModelBounds()
                render.DrawWireframeBox(tilebuildprop:GetPos(), tilebuildprop:GetAngles(), min, max, color_white)
            end

            ply.tilebuild_hitent = tr.Entity

            local spherepos = tr.HitPos

            if tr.Entity ~= game.GetWorld() then

                spherepos = ply:GetNW2Vector("tilebuild_dynamicsnappos")

            end

            if tool:GetClientNumber("dynamicsnap") == 0 then

                spherepos = Vector(math.SnapTo(spherepos.x, snapamount / div), math.SnapTo(spherepos.y, snapamount / div), math.SnapTo(spherepos.z, snapamount / div))

            end

            ply.tilebuild_clstartpos = spherepos

        end


        if tool:GetClientNumber("guide") == 1 then

            render.DrawSphere(ply.tilebuild_clstartpos, 1, 10, 10, novec)

        end

    --end



end)

list.Add( "tilebuildmaterials", "No_Material" )
list.Add( "tilebuildmaterials", "models/wireframe" )
list.Add( "tilebuildmaterials", "debug/env_cubemap_model" )
list.Add( "tilebuildmaterials", "models/shadertest/shader3" )
list.Add( "tilebuildmaterials", "models/shadertest/shader4" )
list.Add( "tilebuildmaterials", "models/shadertest/shader5" )
list.Add( "tilebuildmaterials", "models/shiny" )
list.Add( "tilebuildmaterials", "models/debug/debugwhite" )
list.Add( "tilebuildmaterials", "Models/effects/comball_sphere" )
list.Add( "tilebuildmaterials", "Models/effects/comball_tape" )
list.Add( "tilebuildmaterials", "Models/effects/splodearc_sheet" )
list.Add( "tilebuildmaterials", "Models/effects/vol_light001" )
list.Add( "tilebuildmaterials", "models/props_combine/stasisshield_sheet" )
list.Add( "tilebuildmaterials", "models/props_combine/portalball001_sheet" )
list.Add( "tilebuildmaterials", "models/props_combine/com_shield001a" )
list.Add( "tilebuildmaterials", "models/props_c17/frostedglass_01a" )
list.Add( "tilebuildmaterials", "models/props_lab/Tank_Glass001" )
list.Add( "tilebuildmaterials", "models/props_combine/tprings_globe" )
list.Add( "tilebuildmaterials", "models/rendertarget" )
list.Add( "tilebuildmaterials", "models/screenspace" )
list.Add( "tilebuildmaterials", "brick/brick_model" )
list.Add( "tilebuildmaterials", "models/props_pipes/GutterMetal01a" )
list.Add( "tilebuildmaterials", "models/props_pipes/Pipesystem01a_skin3" )
list.Add( "tilebuildmaterials", "models/props_wasteland/wood_fence01a" )
list.Add( "tilebuildmaterials", "models/props_foliage/tree_deciduous_01a_trunk" )
list.Add( "tilebuildmaterials", "models/props_c17/FurnitureFabric003a" )
list.Add( "tilebuildmaterials", "models/props_c17/FurnitureMetal001a" )
list.Add( "tilebuildmaterials", "models/props_c17/paper01" )
list.Add( "tilebuildmaterials", "models/flesh" )
list.Add( "tilebuildmaterials", "phoenix_storms/metalset_1-2" )
list.Add( "tilebuildmaterials", "phoenix_storms/metalfloor_2-3" )
list.Add( "tilebuildmaterials", "phoenix_storms/plastic" )
list.Add( "tilebuildmaterials", "phoenix_storms/wood" )
list.Add( "tilebuildmaterials", "phoenix_storms/bluemetal" )
list.Add( "tilebuildmaterials", "phoenix_storms/cube" )
list.Add( "tilebuildmaterials", "phoenix_storms/dome" )
list.Add( "tilebuildmaterials", "phoenix_storms/gear" )
list.Add( "tilebuildmaterials", "phoenix_storms/stripes" )
list.Add( "tilebuildmaterials", "phoenix_storms/wire/pcb_green" )
list.Add( "tilebuildmaterials", "phoenix_storms/wire/pcb_red" )
list.Add( "tilebuildmaterials", "phoenix_storms/wire/pcb_blue" )
list.Add( "tilebuildmaterials", "hunter/myplastic" )
list.Add( "tilebuildmaterials", "models/XQM/LightLinesRed_tool" )

list.Set( "tilebuildproptypes", "models/squad/sf_plates/sf_plate4x4.mdl")
list.Set( "tilebuildproptypes", "models/props_phx/construct/metal_plate1.mdl")
list.Set( "tilebuildproptypes", "models/maxofs2d/lamp_projector.mdl")

local proptypes = {

    ["models/squad/sf_plates/sf_plate4x4.mdl"] = {["tilebuild_proptype"] = "superflat"},
    ["models/props_phx/construct/metal_plate1.mdl"] = {["tilebuild_proptype"] = "steel"},
    ["models/props_phx/construct/metal_wire1x1.mdl"] = {["tilebuild_proptype"] = "steelframe"},
    ["models/hunter/plates/plate1x1.mdl"] = {["tilebuild_proptype"] = "plastic"},
    ["models/props_phx/construct/wood/wood_panel1x1.mdl"] = {["tilebuild_proptype"] = "wood"},
    ["models/props_phx/construct/wood/wood_wire1x1.mdl"] = {["tilebuild_proptype"] = "woodframe"},
    ["models/props_phx/construct/glass/glass_plate1x1.mdl"] = {["tilebuild_proptype"] = "glass"},
    ["models/props_phx/construct/windows/window1x1.mdl"] = {["tilebuild_proptype"] = "strongglass"},
    ["models/props_phx/construct/plastic/plastic_panel1x1.mdl"] = {["tilebuild_proptype"] = "floatyplastic"},

}



function TOOL.BuildCPanel( DForm )


    if GetConVar("tilebuild_sprops"):GetFloat() == 1 then

        proptypes = {
            ["models/squad/sf_plates/sf_plate4x4.mdl"] = {["tilebuild_proptype"] = "superflat"},
            ["models/props_phx/construct/metal_plate1.mdl"] = {["tilebuild_proptype"] = "steel"},
            ["models/props_phx/construct/metal_wire1x1.mdl"] = {["tilebuild_proptype"] = "steelframe"},
            ["models/hunter/plates/plate1x1.mdl"] = {["tilebuild_proptype"] = "plastic"},
            ["models/props_phx/construct/wood/wood_panel1x1.mdl"] = {["tilebuild_proptype"] = "wood"},
            ["models/props_phx/construct/wood/wood_wire1x1.mdl"] = {["tilebuild_proptype"] = "woodframe"},
            ["models/props_phx/construct/glass/glass_plate1x1.mdl"] = {["tilebuild_proptype"] = "glass"},
            ["models/props_phx/construct/windows/window1x1.mdl"] = {["tilebuild_proptype"] = "strongglass"},
            ["models/sprops/rectangles/size_3/rect_24x24x3.mdl"] = {["tilebuild_proptype"] = "sprops"},
            ["models/props_phx/construct/plastic/plastic_panel1x1.mdl"] = {["tilebuild_proptype"] = "floatyplastic"},
            ["models/sprops/rectangles_superthin/size_3/rect_24x24.mdl"] = {["tilebuild_proptype"] = "spropsp2"},
            ["models/sprops/rectangles_thin/size_3/rect_24x24x1_5.mdl"] = {["tilebuild_proptype"] = "spropsp1"},
        }

    end

    DForm:SetName( "Tile Build" )

    DForm:CheckBox( "Preview Line + Sphere", "tilebuild_guide" )
    DForm:ControlHelp("Display a diagonal line through inputted dimensions and a sphere to gauge distance.")

    DForm:CheckBox( "Preview Box", "tilebuild_previewbox" )
    DForm:ControlHelp("Displays your inputted dimensions.")

    DForm:CheckBox( "Prop Outline", "tilebuild_outline" )
    DForm:ControlHelp("Display an outline around your current prop.")

    DForm:CheckBox( "Dynamic Snapping", "tilebuild_dynamicsnap" )
    DForm:ControlHelp("Attempts to sync grid with targeted prop.")

    --[[DForm:CheckBox( "Debug mode.", "tilebuild_debug" )
    DForm:ControlHelp("Not recommended if you have a slow PC. Or at all really.")]]

    DForm:NumSlider( "Snap Divisor", "tilebuild_snapdivision", 1, 6, 0)
    DForm:ControlHelp("Shrink the grid by set factor. Creates more snap points.")

    DForm:PropSelect( "Prop Type", nil, proptypes,  2 )

    DForm.ColorSelect = DForm:AddControl("Color", {
        ["label"] = "",
        ["red"] = "tilebuild_red",
        ["green"] = "tilebuild_green",
        ["blue"] = "tilebuild_blue",
        ["alpha"] = "tilebuild_alpha"
    })

    DForm.Material = DForm:MatSelect("tilebuild_material", list.Get("tilebuildmaterials"), true, 0.25, 0.25)


end