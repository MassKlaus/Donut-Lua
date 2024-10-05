local K1 = 0
local K2 = 0

local screen_size = { height = 50, width = 50 }

local center_radius = 50 -- The Donut hole radius
local edge_radius = 10   -- The Circle inside that forms the thickness of the donut
local screen_donut_distance = 200
local camera_screen_distance = 40
local camera_donut_distance = camera_screen_distance + screen_donut_distance

local lightLevel = {
    ". ",
    "- ",
    "^ ",
    "* ",
    ": ",
    "| ",
    "$ ",
    "# ",
    "@ ",
}

local lightLevelCount = 0
for _ in pairs(lightLevel) do lightLevelCount = lightLevelCount + 1 end


local buffers = {
    screen = {},
    z = {},
}

function InitScreenBuffer()
    for i = 1, screen_size.height, 1 do
        buffers.screen[i] = {}
        buffers.z[i] = {}
        for j = 1, screen_size.width, 1 do
            buffers.screen[i][j] = '  '
            buffers.z[i][j] = 0
        end
    end
end

local phi_step = 0.07   -- Donut Edge, larger step since radius is smaller
local theta_step = 0.02 -- Donut center, smaller step to skip less pixels

MAX_ANGLE = math.pi * 2

local A = 0 -- Rotation Angle on the Y axis
local B = 0 -- Rotation Angle on the Y axis


function RenderFrame()
    local cosA = math.cos(A)
    local sinA = math.sin(A)
    local cosB = math.cos(B)
    local sinB = math.sin(B)

    for theta = 0, MAX_ANGLE, theta_step do
        local cos_theta = math.cos(theta)
        local sin_theta = math.sin(theta)

        local center_x = 0;
        local center_y = center_radius * sin_theta
        local center_z = center_radius * cos_theta

        for phi = 0, MAX_ANGLE, phi_step do
            local cos_phi = math.cos(phi)
            local sin_phi = math.sin(phi)

            local relative_edge_x = edge_radius * cos_phi
            local relative_edge_z = edge_radius * sin_phi

            -- rotate 2D plane by theta or something, I'll just use the simpler way of and rotate the point with a matrix in 3D space

            local rotated_edge_x = relative_edge_x
            local rotated_edge_y = relative_edge_z * sin_theta
            local rotated_edge_z = relative_edge_z * cos_theta

            local point_x = rotated_edge_x + center_x;
            local point_y = rotated_edge_y + center_y;
            local point_z = rotated_edge_z + center_z;

            local center_rotated_x = point_x * cosA - point_y * sinA
            local center_rotated_y = point_x * sinA + point_y * cosA
            local center_rotated_z = point_z

            local center_B_rotated_x = center_rotated_x * cosB - center_rotated_z * sinB
            local center_B_rotated_y = center_rotated_y
            local center_B_rotated_z = center_rotated_x * sinB + center_rotated_z * cosB

            local x = center_B_rotated_x + camera_donut_distance
            local y = center_B_rotated_y
            local z = center_B_rotated_z

            local screen_y = math.floor((y * camera_screen_distance) / x) + (screen_size.width / 2) + 1
            local screen_z = math.floor((z * camera_screen_distance) / x) + (screen_size.height / 2) + 1

            local direction_x = center_x * cosA - center_y * sinA
            local direction_y = center_x * sinA + center_y * cosA
            local direction_z = center_z

            local final_direction_x = direction_x * cosB - direction_z * sinB
            local final_direction_y = direction_y
            local final_direction_z = direction_x * sinB + direction_z * cosB

            local face_x = center_B_rotated_x - final_direction_x
            local face_y = center_B_rotated_y - final_direction_y
            local face_z = center_B_rotated_z - final_direction_z

            local magnitude_camera = math.sqrt(200 * 200 + screen_y * screen_y + screen_z * screen_z)
            local magnitude_face = math.sqrt(face_x * face_x + face_y * face_y + face_z * face_z)

            local L = math.max(0,
                -(((face_x) * 200 + (face_y) * screen_y + (face_z) * screen_z) / (magnitude_face * magnitude_camera)))
            local depth = 1 / x

            if L > 0 and depth > buffers.z[screen_z][screen_y] and screen_y < screen_size.height and screen_y > 0 and screen_z < screen_size.width and screen_z > 0 then
                buffers.screen[screen_z][screen_y] = lightLevel[math.ceil(L * L * L * L * lightLevelCount)]
                buffers.z[screen_z][screen_y] = depth
            end
        end
    end
end

function PrintFrame()
    io.write("\27[H")

    local sya = "Sya Is The Best!"
    local length = string.len(sya)
    local start = math.ceil((screen_size.width - length) / 2) + 5
    local y = math.ceil(screen_size.height / 2)

    local index = 1

    for i = 1, screen_size.height, 1 do
        local line = "";
        for j = 1, screen_size.width, 1 do
            -- if j >= start and j <= (start + (length / 2) - 1) and i == y then
            --     if index <= length then
            --         line = line .. string.sub(sya, index, index);
            --         index = index + 1
            --     else
            --         line = line .. ' ';
            --     end

            --     if index <= length then
            --         line = line .. string.sub(sya, index, index);
            --         index = index + 1
            --     else
            --         line = line .. ' ';
            --     end
            -- else
            line = line .. buffers.screen[i][j];
            -- end
        end
        io.write(line .. '\n')
    end

    io.flush()
    os.execute("pwsh 'sleep 0.1' > NUL")
end

while true do
    InitScreenBuffer()
    RenderFrame()
    PrintFrame()
    A = A + math.pi / 64
    B = B + math.pi * 2 / 64
end
