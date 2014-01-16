use Module::Build;

Module::Build->new(
    module_name		=> "App::Jacana",
    license		=> "bsd",
    requires            => {
        "Audio::FluidSynth" => "0",
        "Cairo"             => "0",
        "Font::FreeType"    => "0",
        "Gtk2"              => "0",
        "Moo"               => "0",
        "MooX::Gtk2"        => "0",
        "YAML::XS"          => "0",
    },
    configure_requires	=> {
	"Module::Build"	    => "0.38",
    },
    build_requires	=> {
	"Test::More"	    => "0.96",
    },
    share_dir           => "share",
    meta_merge		=> {
	resources   => {
	    repository => "http://github.com/mauzo/App-Jacana",
	    bugtracker => "https://rt.cpan.org/Public/Dist/" .
		"Display.html?Name=App-Jacana",
	},
    },
)->create_build_script;
