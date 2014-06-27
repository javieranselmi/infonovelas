require 'lib/utf8'

------------------------------------------------------------------------
GingaVersion = {
["GINGA_AR_2_2"] = "Ginga.ar r2.2";
["GINGA_AR_2_1"] = "Ginga.ar 2.1";
["GINGA_AR_2_0"] = "Ginga.ar 2.0";
["UNKNOWN"] = "desconocido";
}

------------------------------------------------------------------------
DeviceModel = {
["STB_UTE_740"] 			= {id = "STB_UTE_740", 				name = "ute 740"};
["STB_UTE_742"]				= {id = "STB_UTE_742", 				name = "ute 742a"};
["STB_KAON_FR9100"]			= {id = "STB_KAON_FR9100", 			name = "kaon fr9100 | coradir 3000d"};
["STB_CORADIR_1000D"]		= {id = "STB_CORADIR_1000D", 		name = "coradir 1000d"};
["STB_CORADIR_1800D"]		= {id = "STB_CORADIR_1800D", 		name = "coradir 1800d"};
["STB_CORADIR_3000D"]		= {id = "STB_CORADIR_3000D", 		name = "kaon fr9100 | coradir 3000d"};
["STB_NEWTRONIC_TOSHIBA"] 	= {id = "STB_NEWTRONIC_TOSHIBA", 	name = "newtronic dv-5306-satvd-t toshiba"};
["STB_NEWTRONIC_TOSHIBA_U"] = {id = "STB_NEWTRONIC_TOSHIBA_U", 	name = "newtronic dv-5306-satvd-t toshiba updated"};
["STB_NEWTRONIC_DIBCOM"] 	= {id = "STB_NEWTRONIC_DIBCOM", 	name = "newtronic dv-5306-satvd-t dibcom"};
["STB_NEWTRONIC_DIBCOM_U"] 	= {id = "STB_NEWTRONIC_DIBCOM_U", 	name = "newtronic dv-5306-satvd-t dibcom updated"};
["UNKNOWN"]					= {id = "UNKNOWN", 	name = "desconocido"};
}

------------------------------------------------------------------------
local _currSTBModel = nil
local _gingaVersion = nil
local _systemMemory = nil
local _stringEncoding = nil

------------------------------------------------------------------------
local function initStringEncoding()
	local gingaVersion = _getGingaVersion()

	if gingaVersion == GingaVersion.UNKNOWN then
		local model = _getAssumedDeviceModel()
	
		if 	model == DeviceModel.STB_UTE_740 or
			model == DeviceModel.STB_UTE_742 or
			model == DeviceModel.STB_KAON_FR9100 or
			model == DeviceModel.STB_CORADIR_1800D or
			model == DeviceModel.STB_CORADIR_3000D or
			model == DeviceModel.STB_NEWTRONIC_TOSHIBA_U or
			model == DeviceModel.STB_NEWTRONIC_DIBCOM_U then

			_stringEncoding = Encoding.UTF_8

		elseif	model == DeviceModel.STB_CORADIR_1000D or
				model == DeviceModel.STB_NEWTRONIC_TOSHIBA or
				model == DeviceModel.STB_NEWTRONIC_DIBCOM then

			_stringEncoding = Encoding.ISO_8859_1

		else
			_stringEncoding = nil
		end

	elseif 	gingaVersion == GingaVersion.GINGA_AR_2_0 or 
			gingaVersion == GingaVersion.GINGA_AR_2_1 then

		_stringEncoding = Encoding.UTF_8
	else
		_stringEncoding = Encoding.ISO_8859_1
	end
end

------------------------------------------------------------------------
-- _deviceVersionInit()
-- Inicializa las variables necesarias para deducir características del dispositivo que ejecuta la aplicación.
function _deviceVersionInit()
	if _getGingaVersion() == GingaVersion.UNKNOWN then
		event.post({ class = 'ncl', type='attribution', name='ncl_dummy', action='start', value='' })
		event.post({ class = 'ncl', type='attribution', name='ncl_dummy', action='stop', value='' })
	else
		_systemMemory = settings.system.memory
		initStringEncoding()
	end
end

------------------------------------------------------------------------
-- _deviceVersionHandler(evt)
-- Atiende eventos para inicializar la variable de capacidad de memoria del dispositivo.
function _deviceVersionHandler(evt)
	if evt.class == "ncl" and evt.type == "attribution" and evt.action == "start" and evt.name == "ncl_system_memory" then
		_systemMemory = evt.value
		initStringEncoding()
		return true
	end
	
	return false
end

------------------------------------------------------------------------
-- _getAssumedDeviceModel()
-- Analiza variables internas del dispositivo que ejecuta la aplicación
-- para deducir (categorizar) su modelo de hardware y versión de firmware.
-- Retorna:
-- 		tabla. tabla.id es un identificador del dispositivo, y tabla.name es el nombre del dispositivo.
function _getAssumedDeviceModel()
	if _systemMemory == nil then
		return nil
	end

	if _currSTBModel == nil then
		_currSTBModel = DeviceModel.UNKNOWN

		---------------------------------------------------------------------------------------------------------
		-- IMPORTANTE:
		-- Coradir 3000D y KAON tienen el mismo valor de memoria.
		-- En un futuro sería deseable poder discriminarlos de alguna manera.
		---------------------------------------------------------------------------------------------------------
		
		if 		_systemMemory == "49225728" 	then _currSTBModel = DeviceModel.STB_UTE_740 -- actualizado o no actualizado
		elseif 	_systemMemory == "311037952" 	then _currSTBModel = DeviceModel.STB_UTE_742
		elseif 	_systemMemory == "832712704" 	then _currSTBModel = DeviceModel.STB_KAON_FR9100 -- en un futuro habria otra version de fw
		elseif 	_systemMemory == "832712704" 	then _currSTBModel = DeviceModel.STB_CORADIR_3000D
		elseif 	_systemMemory == "109117440" 	then _currSTBModel = DeviceModel.STB_CORADIR_1800D
		elseif 	_systemMemory == "6.323e+07" 	then _currSTBModel = DeviceModel.STB_NEWTRONIC_TOSHIBA
		elseif 	_systemMemory == "63229952" 	then _currSTBModel = DeviceModel.STB_NEWTRONIC_TOSHIBA_U
		elseif 	_systemMemory == "63234048" 	then _currSTBModel = DeviceModel.STB_NEWTRONIC_DIBCOM_U
		elseif 	_systemMemory == "6.3234e+07" 	then
			if os ~= nil and os.getenv ~= nil then
			   	local hostname = os.getenv("HOSTNAME") 
				
				if 		hostname == "uclibc"	then _currSTBModel = DeviceModel.STB_NEWTRONIC_DIBCOM
				elseif 	hostname == "(none)"	then _currSTBModel = DeviceModel.STB_CORADIR_1000D
				end
			end
		end
	end
	
	return _currSTBModel
end

------------------------------------------------------------------------
-- _getDeviceStringEncoding()
-- Retorna el tipo de codificación de caracteres utilizado por el dispositivo.
-- Si el dispositivo es desconocido devuelve nil.
function _getDeviceStringEncoding()
	return _stringEncoding
end

------------------------------------------------------------------------
-- _getGingaVersion()
-- Utiliza variables internas de Ginga para deducir la versión de la implementación
-- de Ginga en la que se basa la versión Ginga del dispositivo.
-- Retorna:
-- 		cadena de caracteres.
function _getGingaVersion()
	if _gingaVersion == nil then
		if settings ~= nil and settings.system ~= nil then

			local gv = settings.system.gingaNCLVersion	-- Ginga.ar 2.1 y 2.2
			if gv == nil then
				gv = settings.system.GingaNCL.version	-- Ginga.ar 2.0 y Ginga brasilero

				if gv == nil then
					gv = GingaVersion.UNKNOWN
				end
			end

			_gingaVersion = gv
		else
			_gingaVersion = GingaVersion.UNKNOWN
		end
	end
	
	return _gingaVersion
end

------------------------------------------------------------------------
-- _getSystemMemory()
-- Retorna el valor de capacidad de memoria (variable interna) del dispositivo.
function _getSystemMemory()
	return _systemMemory
end

------------------------------------------------------------------------
