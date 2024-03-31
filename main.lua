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

Whiteball = Ball:new{pos=Vector:new(400, 300), radius=10, vel=Vector:new(300, 0), friction=0.995}

Balls = {
    Whiteball,
    Ball:new{pos=Vector:new(350, 250), radius=10, vel=Vector:new(300, 0), friction=0.995}
}

-- borrowed and translated from c++ here https://stackoverflow.com/questions/68231954/2d-elastic-collision-with-circles
local function resolveBallCollision2(ball, otherBall)
    local m1 = 10
    local m2 = 10

    -- normal vector
    local nvec = Vector:new(otherBall.pos.x - ball.pos.x, otherBall.pos.y - ball.pos.y)
    -- unit vector
    local unvec = Vector:new(
        nvec.x / math.sqrt((nvec.x * nvec.x) + (nvec.y * nvec.y)),
        nvec.y / math.sqrt((nvec.x * nvec.x) + (nvec.y * nvec.y))
    )
    -- unit tangent vec
    local utvec = Vector:new(-unvec.y, unvec.x)

    local v1n = (unvec.x * ball.vel.x) + (unvec.y * ball.vel.y)
    local v2n = (unvec.x * otherBall.vel.x) + (unvec.y * otherBall.vel.y)
    -- why otherball in second part here?!
    local v1t = (utvec.x * ball.vel.x) + (utvec.y * ball.vel.y)
    local v2t = (utvec.x * otherBall.vel.x) + (utvec.y * otherBall.vel.y)

    -- v1t and v1n after collision
    local v1tn = v1t
    local v2tn = v2t
    local v1nn = (v1n * (m1 - m2) + (2 * m2) * v2n) / (m1 + m2)
    local v2nn = (v2n * (m2 - m1) + (2 * m1) * v1n) / (m1 + m2)

    -- new velocities
    local vel1n = Vector:new(unvec.x * v1nn, unvec.y * v1nn)
    local vel1tn = Vector:new(utvec.x * v1tn, utvec.y * v1tn)
    local vel2n = Vector:new(unvec.x * v2nn, unvec.y * v2nn)
    local vel2tn = Vector:new(utvec.x * v2tn, utvec.y * v2tn)
    ball.vel = Vector:new(vel1n.x + vel1tn.x, vel1n.y + vel1tn.y)
    otherBall.vel = Vector:new(vel2n.x + vel2tn.x, vel2n.y + vel2tn.y)
end

local function resolveBallCollision(ball, otherBall)
    local dPos = Vector:new(ball.pos.x - otherBall.pos.x, ball.pos.y - otherBall.pos.y)
    local dVel = Vector:new(ball.vel.x - otherBall.vel.x, ball.vel.y - otherBall.vel.y)
    -- Calculate the distance between balls
    local dist = math.sqrt(dPos.x * dPos.x + dPos.y * dPos.y)
    -- Normalize the difference in positions to get the collision normal
    local nVec = Vector:new(dPos.x / dist, dPos.y / dist)
    -- Calculate the dot product of the velocity difference and collision normal
    local dot = dVel.x * nVec.x + dVel.y * nVec.y

    -- If they are moving away from each other there is no need to set vectors
    if dot > 0 then
        return
    end

    -- Calculate the component of the velocities along the collision normal
    ball.vel.x = ball.vel.x + dot * nVec.x
    ball.vel.y = ball.vel.y + dot * nVec.y
    otherBall.vel.x = otherBall.vel.x + dot * nVec.x
    otherBall.vel.y = otherBall.vel.y + dot * nVec.y
end

local function collideWithOtherBalls(ball, oldPos)
    for _, otherBall in ipairs(Balls) do
        if ball == otherBall then
            return
        end

        -- Check if balls collide using position and radius
        -- Clever way to avoid math.sqrt for distance, but alot more complex, probably not worth it...
        -- https://stackoverflow.com/a/8367547
        local cheatDistanceCalc = (ball.pos.x - otherBall.pos.x)^2 + (ball.pos.y - otherBall.pos.y)^2
        if (ball.radius - otherBall.radius)^2 <= cheatDistanceCalc and cheatDistanceCalc <= (ball.radius + otherBall.radius)^2 then
            local dir = otherBall.pos:direction(oldPos)
            ball.pos.x = otherBall.pos.x + (otherBall.radius + ball.radius) * dir.x
            ball.pos.y = otherBall.pos.y + (otherBall.radius + ball.radius) * dir.y
            
            -- ball.vel.y = 0
            -- ball.vel.x = 0
            
            resolveBallCollision2(ball, otherBall)
        end
    end
end

local function updateBalls(dt)
    -- Using a power here could make the friction framerate independent (probably overkill)
    -- Should I try to shoehorn a fixed timestamp in love somehow?
    -- ball.vx = ball.vx * (ball.friction^dt)
    for _, ball in ipairs(Balls) do
        local vMagnitude = math.sqrt(ball.vel.x^2 + ball.vel.y^2)
        local dynamicFriction = ball.friction - (vMagnitude * 0.0015)
        dynamicFriction = math.max(dynamicFriction, 0.99)

        ball.vel.x = ball.vel.x * dynamicFriction
        ball.vel.y = ball.vel.y * dynamicFriction

        if math.abs(ball.vel.x) < 2 then ball.vel.x = 0 end
        if math.abs(ball.vel.y) < 2 then ball.vel.y = 0 end

        local oldPos = Vector:new(ball.pos.x, ball.pos.y)
        ball.pos.x = ball.pos.x + ball.vel.x * dt
        ball.pos.y = ball.pos.y + ball.vel.y * dt

        if (ball.pos.x + ball.radius) > (Table.pos.x + Table.width) or (ball.pos.x - ball.radius) < Table.pos.x then
            if (ball.pos.x + ball.radius) > (Table.pos.x + Table.width) then
                ball.pos.x = Table.pos.x + Table.width - ball.radius
            end
            if (ball.pos.x - ball.radius) < Table.pos.x then
                ball.pos.x = Table.pos.x + ball.radius
            end

            ball.vel.x = (ball.vel.x * Table.cushion_elasticity) * -1
        end

        if (ball.pos.y + ball.radius) > (Table.pos.y + Table.height) or (ball.pos.y - ball.radius) < Table.pos.y then
            if (ball.pos.y + ball.radius) > (Table.pos.y + Table.height) then
                ball.pos.y = Table.pos.y + Table.height - ball.radius
            end
            if (ball.pos.y - ball.radius) < Table.pos.y then
                ball.pos.y = Table.pos.y + ball.radius
            end

            ball.vel.y = (ball.vel.y * Table.cushion_elasticity) * -1
        end

        collideWithOtherBalls(ball, oldPos)
    end
end

function love.load()
end

function love.draw()
    for _, ball in ipairs(Balls) do
        love.graphics.circle('fill', ball.pos.x, ball.pos.y, ball.radius)    
    end
    
    love.graphics.rectangle('line', Table.pos.x, Table.pos.y, Table.width, Table.height, 10, 10)
end

function love.update(dt)
    updateBalls(dt)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local clickPos = Vector:new(x, y)
        local newVelDir = clickPos:direction(Whiteball.pos)
        Whiteball.vel.x = newVelDir.x * 300
        Whiteball.vel.y = newVelDir.y * 300
    end
end
