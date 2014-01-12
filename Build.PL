use Module::Build;

Module::Build->new(
    module_name		=> "App::Jacana",
    license		=> "bsd",
    requires            => {
        "Moo"               => "0",
        "Wx"                => "0",
    },
    configure_requires	=> {
	"Module::Build"	    => "0.38",
    },
    build_requires	=> {
	"Test::More"	    => "0.96",
    },
    meta_merge		=> {
	resources   => {
	    repository => "http://github.com/mauzo/App-Jacana",
	    bugtracker => "https://rt.cpan.org/Public/Dist/" .
		"Display.html?Name=App-Jacana",
	},
    },
)->create_build_script;
