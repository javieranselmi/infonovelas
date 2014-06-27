<?xml version="1.0" encoding="ISO-8859-1"?>
<ncl id="infoNovelas" xmlns="http://www.ncl.org.br/NCL3.0/EDTVProfile">
	<head>
		<regionBase>
			<region id="mainReg" zIndex="2" />
		</regionBase>
		
		<descriptorBase>
			<descriptor id="descLua"  region="mainReg" focusIndex="1" />
		</descriptorBase>

	</head>

	<body>
		<port id="appPort" component="application" />					
		
		<media id="application" src="main.lua" descriptor="descLua"/>

		<media id="varGlobal" type="application/x-ginga-settings" descriptor="descLua">
			<property name="service.currentKeyMaster" value="1"/>
		</media>

	</body>
</ncl>

