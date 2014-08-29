local ffi = require "ffi"
local tconcat = table.concat

ffi.cdef(io.open('markdown.ffi', 'r'):read('*a'))

local libmarkdown
if (ffi.os == 'OSX') then
	libmarkdown = ffi.load('./libsundown.dylib')
else
    libmarkdown = ffi.load('./libsundown.so')
end

local READ_UNIT = 1024
local OUTPUT_UNIT = 64

local ib = ffi.new('struct buf[1]')
local ob = ffi.new('struct buf[1]')
local ret = 0
local callbacks = ffi.new('struct sd_callbacks[1]')
local options = ffi.new('struct html_renderopt[1]')
local markdown = ffi.new('struct sd_markdown *[1]')

ib = libmarkdown.bufnew(READ_UNIT)
libmarkdown.bufgrow(ib, READ_UNIT)
local fname = arg[1]
local f = io.open(fname, "r")
while 1 do
    local size = tonumber(ib.asize - ib.size)
    local words = f:read(size)
    if words == nil then
        break
    else
        ffi.copy(ib.data + ib.size, words, #words)
        ib.size = ib.size + #words
        libmarkdown.bufgrow(ib, ib.size + READ_UNIT)
    end
end

f:close()

ob = libmarkdown.bufnew(OUTPUT_UNIT);

libmarkdown.sdhtml_renderer(callbacks, options, 0);
markdown = libmarkdown.sd_markdown_new(0, 16, callbacks, options);

libmarkdown.sd_markdown_render(ob, ib.data, ib.size, markdown);
libmarkdown.sd_markdown_free(markdown);

local result = ffi.string(ob.data)

io.write(result)
libmarkdown.bufrelease(ib);
libmarkdown.bufrelease(ob);
