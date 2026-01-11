local resourcePath = GetResourcePath(cache.resource):gsub('//', '/') .. '/'

local utils = {}

function utils.getFilesInDirectory(path, pattern)
	local files = {}
	local fileCount = 0
	local system = os.getenv('OS')
	local command = system and system:match('Windows') and 'dir "' or 'ls "'
	local suffix = command == 'dir "' and '/" /b' or '/"'
	local dir = io.popen(command .. resourcePath .. path .. suffix)

	if dir then
		for line in dir:lines() do
			if line:match(pattern) then
				fileCount += 1
				files[fileCount] = line:gsub(pattern, '')
			end
		end

		dir:close()
	end

	return files, fileCount
end

local convarFramework = GetConvar('doorlock:framework', ''):lower()

local frameworks = {
	{ resource = 'es_extended', module = 'es_extended' },
	{ resource = 'ND_Core', module = 'nd_core' },
	{ resource = 'ox_core', module = 'ox_core' },
	{ resource = 'qbx_core', module = 'qbx_core' },
	{ resource = 'qb-core', module = 'qbcore' },
}
local sucess = false

for i = 1, #frameworks do
	local framework = frameworks[i]
	local resource = framework.resource
	local module = framework.module

	if convarFramework ~= '' and convarFramework ~= resource:lower() and convarFramework ~= module then
		goto continue
	end

	if GetResourceState(resource):find('start') then
		require(('server.framework.%s'):format(module:gsub('%-', '_')))
		sucess = true
		break
	end

	::continue::
end

if not sucess then
	warn('no compatible framework was loaded, most features will not work')
end

return utils
