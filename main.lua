Ball = {}
Ball_mt = { __index = Ball }

function Ball:new(args)
    local x = assert(args.x)
    local y = assert(args.y)
    local radius = assert(args.radius)
    local velocity_x = assert(args.velocity_x)
    local velocity_y = assert(args.velocity_y)
    return setmetatable(
        {
            x=x,
            y=y,
            radius=radius,
            velocity_x=velocity_x,
            velocity_y=velocity_y,
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
    Whiteball = Ball:new{x=400, y=300, radius=10, velocity_x=300, velocity_y=0}
end

function love.draw()
    love.graphics.circle('fill', Whiteball.x, Whiteball.y, Whiteball.radius)
    love.graphics.rectangle('line', Table.x, Table.y, Table.width, Table.height, 10, 10)
end

function love.update(dt)
    Whiteball.x = Whiteball.x + (Whiteball.velocity_x * dt)
    if (Whiteball.x + Whiteball.radius) > (Table.x + Table.width) or (Whiteball.x - Whiteball.radius) < Table.x then
        if (Whiteball.x + Whiteball.radius) > (Table.x + Table.width) then
            Whiteball.x = Table.x + Table.width - Whiteball.radius
        end
        if (Whiteball.x - Whiteball.radius) < Table.x then
            Whiteball.x = Table.x + Whiteball.radius
        end
        Whiteball.velocity_x = (Whiteball.velocity_x * Table.cushion_elasticity) * -1
    end
end
