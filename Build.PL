use Module::Build;
use ExtUtils::Depends;
use ExtUtils::ParseXS;

my %dep = ExtUtils::Depends->new("App::Jacana", "Gtk2")
    ->get_makefile_vars;

my $MB = Module::Build->subclass(
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
        "Audio::FluidSynth"             => "0",
        "B::Hooks::AtRuntime"           => "0",
        "Cairo"                         => "0",
        "Data::Dump"                    => "0",
        "File::Path"                    => "0",
        "File::ShareDir"                => "0",
        "File::Slurp"                   => "0",
        "File::Temp"                    => "0",
        "Font::FreeType"                => "0",
        "Gtk2"                          => "0",
        "Gtk2::Ex::WidgetCursor"        => "0",
        "Hash::Merge"                   => "0",
        "List::BinarySearch"            => "0",
        "List::MoreUtils"               => "0",
        "List::Util"                    => "0",
        "Memoize"                       => "0",
        "Module::Runtime"               => "0",
        "Moose"                         => "0",
        "MooseX::AttributeShortcuts"    => "0",
        "MooseX::Gtk2"                  => "0",
        "Pango"                         => "0",
        "Readonly::Tiny"                => "0",
        "Regexp::Common"                => "0",
        "Text::Wrap"                    => "0",
        "Time::HiRes"                   => "0",
        "Try::Tiny"                     => "0",
        "Type::Tiny"                    => "0",
        "XML::LibXML"                   => "0",
        "YAML::XS"                      => "0",
        "namespace::autoclean"          => "0",
    },
    configure_requires	=> {
        "ExtUtils::Depends" => "0",
        "Gtk2"              => "0",
	"Module::Build"	    => "0.38",
    },
    build_requires	=> {
	"Test::More"	    => "0.96",
    },

    extra_compiler_flags    => $dep{INC},
    extra_linker_flags      => $dep{LIB},
    typemaps                => $dep{TYPEMAPS},

    share_dir           => "share",
    PL_files            => {
        "xdg/Jacana.desktop.PL" => "xdg/Jacana.desktop",
    },
    xdg_files           => {
        "xdg/Jacana.desktop"    => "xdg/applications/Jacana.desktop",
        "xdg/Jacana.png"        => "xdg/icons/hicolor/48x48/Jacana.png",
    },
    install_path        => {
        xdg     =>          "/usr/local/share",
    },

    meta_merge		=> {
	resources   => {
	    repository => "http://github.com/mauzo/App-Jacana",
	    bugtracker => "https://rt.cpan.org/Public/Dist/" .
		"Display.html?Name=App-Jacana",
	},
    },
);
$MB->add_build_element("xdg");
$MB->create_build_script;
