local ZipWriter = {}

local bit = require("bit")

local crc_table = {}
for i = 0, 255 do
    local c = i
    for j = 1, 8 do
        if bit.band(c, 1) == 1 then
            c = bit.bxor(bit.rshift(c, 1), 0xEDB88320)
        else
            c = bit.rshift(c, 1)
        end
    end
    crc_table[i] = c
end

local function crc32(s)
    local crc = 0xFFFFFFFF
    for i = 1, #s do
        local byte = s:byte(i)
        local idx = bit.bxor(bit.band(crc, 0xFF), byte)
        crc = bit.bxor(bit.rshift(crc, 8), crc_table[idx])
    end
    -- In LuaJIT, bit operations result in signed 32-bit integers
    -- We need to convert it to an unsigned 32-bit integer for pack
    local result = bit.bxor(crc, 0xFFFFFFFF)
    if result < 0 then result = result + 4294967296 end
    return result
end

function ZipWriter.write(files)
    -- files is an array of tables: {name="...", data="...", time=..., date=...}
    
    local out = {}
    local central_dir = {}
    local offset = 0
    
    for _, f in ipairs(files) do
        local name = f.name
        local data = f.data
        local crc_num = crc32(data)
        local size = #data
        
        -- Default DOS time/date (not strictly necessary for simple extraction)
        local time = 0
        local date = 0
        
        -- Local File Header
        local lfh = {}
        table.insert(lfh, "PK\3\4") -- Signature
        table.insert(lfh, string.pack("<I2", 10)) -- Version needed (1.0)
        table.insert(lfh, string.pack("<I2", 0))  -- Flags
        table.insert(lfh, string.pack("<I2", 0))  -- Compression (0 = store)
        table.insert(lfh, string.pack("<I2", time))
        table.insert(lfh, string.pack("<I2", date))
        table.insert(lfh, string.pack("<I4", crc_num))
        table.insert(lfh, string.pack("<I4", size)) -- compressed size
        table.insert(lfh, string.pack("<I4", size)) -- uncompressed size
        table.insert(lfh, string.pack("<I2", #name))
        table.insert(lfh, string.pack("<I2", 0)) -- extra field length
        table.insert(lfh, name)
        
        local lfh_str = table.concat(lfh)
        table.insert(out, lfh_str)
        table.insert(out, data)
        
        -- Central Directory Header
        local cdh = {}
        table.insert(cdh, "PK\1\2") -- Signature
        table.insert(cdh, string.pack("<I2", 0)) -- Version made by
        table.insert(cdh, string.pack("<I2", 10)) -- Version needed
        table.insert(cdh, string.pack("<I2", 0))  -- Flags
        table.insert(cdh, string.pack("<I2", 0))  -- Compression
        table.insert(cdh, string.pack("<I2", time))
        table.insert(cdh, string.pack("<I2", date))
        table.insert(cdh, string.pack("<I4", crc_num))
        table.insert(cdh, string.pack("<I4", size))
        table.insert(cdh, string.pack("<I4", size))
        table.insert(cdh, string.pack("<I2", #name))
        table.insert(cdh, string.pack("<I2", 0)) -- extra field length
        table.insert(cdh, string.pack("<I2", 0)) -- file comment length
        table.insert(cdh, string.pack("<I2", 0)) -- disk number start
        table.insert(cdh, string.pack("<I2", 0)) -- internal file attr
        table.insert(cdh, string.pack("<I4", 0)) -- external file attr
        table.insert(cdh, string.pack("<I4", offset)) -- local header offset
        table.insert(cdh, name)
        
        local cdh_str = table.concat(cdh)
        table.insert(central_dir, cdh_str)
        
        offset = offset + #lfh_str + size
    end
    
    local cd_str = table.concat(central_dir)
    local cd_size = #cd_str
    
    -- End of Central Directory Record
    local eocd = {}
    table.insert(eocd, "PK\5\6") -- Signature
    table.insert(eocd, string.pack("<I2", 0)) -- this disk
    table.insert(eocd, string.pack("<I2", 0)) -- cd disk
    table.insert(eocd, string.pack("<I2", #files)) -- records on this disk
    table.insert(eocd, string.pack("<I2", #files)) -- total records
    table.insert(eocd, string.pack("<I4", cd_size)) -- cd size
    table.insert(eocd, string.pack("<I4", offset)) -- cd offset
    table.insert(eocd, string.pack("<I2", 0)) -- comment length
    
    table.insert(out, cd_str)
    table.insert(out, table.concat(eocd))
    
    return table.concat(out)
end

return ZipWriter
