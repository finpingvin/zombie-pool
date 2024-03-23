Vector = {}
Vector_mt = { __index = Vector }

function Vector:new(x, y)
    local x = assert(x)
    local y = assert(y)
    return setmetatable(
        { x=x, y=y },
        Vector_mt
    )
end

function Vector:direction(otherVector)
    local dx = otherVector.x - self.x
    local dy = otherVector.y - self.y
    local magnitude = math.sqrt(dx^2 + dy^2)
    local ux = dx / magnitude
    local uy = dy / magnitude

    return Vector:new(ux, uy)
end

Ball = {}
Ball_mt = { __index = Ball }

function Ball:new(args)
    local pos = assert(args.pos)
    local radius = assert(args.radius)
    local vel = assert(args.vel)
    local friction = assert(args.friction)
    return setmetatable(
        {
            pos=pos,
            radius=radius,
            vel=vel,
            friction=friction,
        },
        Ball_mt
    )
end

Table = {
    pos=Vector:new(300, 100),
    width=200,
    height=400,
    cushion_elasticity=0.8,
}

function love.load()
    Whiteball = Ball:new{pos=Vector:new(400, 300), radius=10, vel=Vector:new(300, 0), friction=0.995}
end

function love.draw()
    love.graphics.circle('fill', Whiteball.pos.x, Whiteball.pos.y, Whiteball.radius)
    love.graphics.rectangle('line', Table.pos.x, Table.pos.y, Table.width, Table.height, 10, 10)
end

function love.update(dt)
    -- Using a power here could make the friction framerate independent (probably overkill)
    -- Should I try to shoehorn a fixed timestamp in love somehow?
    -- Whiteball.vx = Whiteball.vx * (Whiteball.friction^dt)

    local vMagnitude = math.sqrt(Whiteball.vel.x^2 + Whiteball.vel.y^2)
    local dynamicFriction = Whiteball.friction - (vMagnitude * 0.0015)
    dynamicFriction = math.max(dynamicFriction, 0.99)

    Whiteball.vel.x = Whiteball.vel.x * dynamicFriction
    Whiteball.vel.y = Whiteball.vel.y * dynamicFriction

    if math.abs(Whiteball.vel.x) < 2 then Whiteball.vel.x = 0 end
    if math.abs(Whiteball.vel.y) < 2 then Whiteball.vel.y = 0 end

    Whiteball.pos.x = Whiteball.pos.x + Whiteball.vel.x * dt
    Whiteball.pos.y = Whiteball.pos.y + Whiteball.vel.y * dt

    if (Whiteball.pos.x + Whiteball.radius) > (Table.pos.x + Table.width) or (Whiteball.pos.x - Whiteball.radius) < Table.pos.x then
        if (Whiteball.pos.x + Whiteball.radius) > (Table.pos.x + Table.width) then
            Whiteball.pos.x = Table.pos.x + Table.width - Whiteball.radius
        end
        if (Whiteball.pos.x - Whiteball.radius) < Table.pos.x then
            Whiteball.pos.x = Table.pos.x + Whiteball.radius
        end

        Whiteball.vel.x = (Whiteball.vel.x * Table.cushion_elasticity) * -1
    end

    if (Whiteball.pos.y + Whiteball.radius) > (Table.pos.y + Table.height) or (Whiteball.pos.y - Whiteball.radius) < Table.pos.y then
        if (Whiteball.pos.y + Whiteball.radius) > (Table.pos.y + Table.height) then
            Whiteball.pos.y = Table.pos.y + Table.height - Whiteball.radius
        end
        if (Whiteball.pos.y - Whiteball.radius) < Table.pos.y then
            Whiteball.pos.y = Table.pos.y + Whiteball.radius
        end

        Whiteball.vel.y = (Whiteball.vel.y * Table.cushion_elasticity) * -1
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local clickPos = Vector:new(x, y)
        local newVelDir = clickPos:direction(Whiteball.pos)
        Whiteball.vel.x = newVelDir.x * 300
        Whiteball.vel.y = newVelDir.y * 300
    end
end
