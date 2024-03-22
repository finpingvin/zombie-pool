Ball = {}
Ball_mt = { __index = Ball }

function Ball:new(args)
    local x = assert(args.x)
    local y = assert(args.y)
    local radius = assert(args.radius)
    local vx = assert(args.vx)
    local vy = assert(args.vy)
    local friction = assert(args.friction)
    return setmetatable(
        {
            x=x,
            y=y,
            radius=radius,
            vx=vx,
            vy=vy,
            friction=friction,
        },
        Ball_mt
    )
end

Table = {
    x=300,
    y=100,
    width=200,
    height=400,
    cushion_elasticity=0.8,
}

function love.load()
    Whiteball = Ball:new{x=400, y=300, radius=10, vx=300, vy=0, friction=0.995}
end

function love.draw()
    love.graphics.circle('fill', Whiteball.x, Whiteball.y, Whiteball.radius)
    love.graphics.rectangle('line', Table.x, Table.y, Table.width, Table.height, 10, 10)
end

function love.update(dt)
    -- Using a power here could make the friction framerate independent (probably overkill)
    -- Should I try to shoehorn a fixed timestamp in love somehow?
    -- Whiteball.vx = Whiteball.vx * (Whiteball.friction^dt)

    local vMagnitude = math.sqrt(Whiteball.vx^2 + Whiteball.vy^2)
    local dynamicFriction = Whiteball.friction - (vMagnitude * 0.0015)
    dynamicFriction = math.max(dynamicFriction, 0.99)

    Whiteball.vx = Whiteball.vx * dynamicFriction

    if math.abs(Whiteball.vx) < 2 then Whiteball.vx = 0 end

    Whiteball.x = Whiteball.x + Whiteball.vx * dt

    if (Whiteball.x + Whiteball.radius) > (Table.x + Table.width) or (Whiteball.x - Whiteball.radius) < Table.x then
        if (Whiteball.x + Whiteball.radius) > (Table.x + Table.width) then
            Whiteball.x = Table.x + Table.width - Whiteball.radius
        end
        if (Whiteball.x - Whiteball.radius) < Table.x then
            Whiteball.x = Table.x + Whiteball.radius
        end

        Whiteball.vx = (Whiteball.vx * Table.cushion_elasticity) * -1
    end
end
