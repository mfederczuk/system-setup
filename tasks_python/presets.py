from . import Input
from .preset import Preset

fedora41_daily_driver: Preset = Preset(
	name="Fedora 41 Daily Driver",
	input=Input(
		xdg_config_home="",
	),
)

ubuntu22_04_server: Preset = Preset(
	name="Ubuntu 22.04 Server",
	input=Input(
		xdg_config_home="",
	),
)

android_termux: Preset = Preset(
	name="Android Termux",
	input=Input(
		xdg_config_home="",
	),
)
