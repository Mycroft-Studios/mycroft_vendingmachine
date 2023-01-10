fx_version 'cerulean'
game 'gta5'

name "Mycrofts Vending Machines"
description "GTA:Online Vending Machines"
author "Mycroft"
lua54 'yes'
version "1.0.0"

shared_scripts {
	'@es_extended/imports.lua',
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}
