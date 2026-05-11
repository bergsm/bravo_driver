-- SnakeByte Bravo Lite (1909) - Self-Healing Production Driver
local ffi = require("ffi")

-- 1. Global Datarefs
dataref("gear_n", "sim/flightmodel2/gear/deploy_ratio", "readonly", 0)
dataref("gear_l", "sim/flightmodel2/gear/deploy_ratio", "readonly", 1)
dataref("gear_r", "sim/flightmodel2/gear/deploy_ratio", "readonly", 2)
dataref("battery", "sim/cockpit/electrical/battery_on", "readonly")

-- 2. FFI Setup
ffi.cdef[[
    int hid_init(void);
    void* hid_open_path(const char *path);
    int hid_send_feature_report(void *device, const unsigned char *data, size_t length);
    void hid_close(void *device);
]]

local hid = nil
local target_path = nil
local last_sent_byte = -1
local frame_counter = 0

local success, err = pcall(function() 
    hid = ffi.load("hidapi-hidraw") 
    hid.hid_init()
end)

-- 3. The Search Function (Extracted for reuse)
function find_bravo_lite()
    for i = 0, 63 do
        local uevent_path = "/sys/class/hidraw/hidraw" .. i .. "/device/uevent"
        local f = io.open(uevent_path, "r")
        if f then
            local data = f:read("*a")
            f:close()
            if data:upper():find("294B") and data:upper():find("1909") then
                return "/dev/hidraw" .. i
            end
        end
    end
    return nil
end

-- 4. Main Update Loop (Now with automatic retries)
function update_bravo_lite_leds()
    if not success or not hid then return end

    frame_counter = frame_counter + 1
    if (frame_counter % 5 ~= 0) then return end

    -- SELF-HEALING LOGIC: Keep looking if we haven't found it yet
    if not target_path then
        target_path = find_bravo_lite()
        if target_path then
            logMsg("BRAVO LITE FFI: Hardware discovered on " .. target_path .. " after boot.")
        else
            return -- Silently exit and try again next loop
        end
    end

    local led_byte = 0
    
    if gear_l ~= nil and gear_n ~= nil and gear_r ~= nil and battery ~= nil then
        if gear_l > 0.99 then led_byte = led_byte + 1 elseif gear_l > 0.1 then led_byte = led_byte + 2 end
        if gear_n > 0.99 then led_byte = led_byte + 4 elseif gear_n > 0.1 then led_byte = led_byte + 8 end
        if gear_r > 0.99 then led_byte = led_byte + 16 elseif gear_r > 0.1 then led_byte = led_byte + 32 end
        -- if battery == 0 then led_byte = 0 end
    end

    if led_byte ~= last_sent_byte then
        local handle = hid.hid_open_path(target_path)
        if handle ~= nil then
            local buf = ffi.new("unsigned char[64]")
            buf[0] = 101
            buf[2] = led_byte
            
            hid.hid_send_feature_report(handle, buf, 64)
            hid.hid_close(handle) 
            
            last_sent_byte = led_byte
        else
            -- If the handle fails to open (e.g., unplugged), reset target path to trigger a new search
            target_path = nil
        end
    end
end

-- 5. Shutdown Handler
function bravo_lite_shutdown()
    if target_path and hid then
        local handle = hid.hid_open_path(target_path)
        if handle ~= nil then
            local buf = ffi.new("unsigned char[64]")
            buf[0] = 101
            buf[2] = 0 
            hid.hid_send_feature_report(handle, buf, 64)
            hid.hid_close(handle)
        end
    end
end

do_every_frame("update_bravo_lite_leds()")
do_on_exit("bravo_lite_shutdown()")
