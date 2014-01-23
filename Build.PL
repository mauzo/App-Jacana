use Module::Build;
use ExtUtils::Depends;
use ExtUtils::ParseXS;
use Data::Dump qw/pp/;

my %dep = ExtUtils::Depends->new("App::Jacana", "Gtk2")
    ->get_makefile_vars;

Module::Build->subclass(
    code => q{  # yuck
        require ExtUtils::ParseXS;

        __PACKAGE__->add_property("typemaps", []);

        sub compile_xs {
            my ($self, $file, %args) = @_;
            ExtUtils::ParseXS::process_file(
                filename    => $file,
                prototypes  => 0,
                output      => $args{outfile},
                typemap     => $self->typemaps,
            );
        }
    },
)->new(
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
        "ExtUtils::Depends" => "0",
	"Module::Build"	    => "0.38",
    },
    build_requires	=> {
	"Test::More"	    => "0.96",
    },

    extra_compiler_flags    => $dep{INC},
    extra_linker_flags      => $dep{LIB},
    typemaps                => $dep{TYPEMAPS},

    share_dir           => "share",
    meta_merge		=> {
	resources   => {
	    repository => "http://github.com/mauzo/App-Jacana",
	    bugtracker => "https://rt.cpan.org/Public/Dist/" .
		"Display.html?Name=App-Jacana",
	},
    },
)->create_build_script;
