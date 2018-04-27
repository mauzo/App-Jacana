package App::Jacana::Log;

use 5.012;
use warnings;

use Carp;
use Data::Dump  qw/pp/;
use Exporter    qw/import/;
use List::Util  qw/uniqnum/;

our @EXPORT = qw/msg msgf/;

my %Active  = (ERR => 1, WARN => 1);
my $Verbose = 0;
my $Suspend = [];
my @LogFH;
my $Prefix  = "";

sub suspend_log;

sub warnx { say STDERR map +(ref ? pp $_ : $_), @_ }

sub msg {
    my ($fac, @msg) = @_;

    @LogFH or suspend_log;

    $Suspend and push(@$Suspend, [$fac, @msg]), return;
    $Verbose || $Active{$fac} or return;

    say $_ "$Prefix$fac: ", map +(ref ? pp $_ : $_), @msg 
        for @LogFH;
}

sub msgf {
    my ($fac, $fmt, @args) = @_;
    msg $fac, sprintf $fmt, @args;
}

sub set_active {
    my %act = @_;
    $Active{$_} = $act{$_} for keys %act;
}

sub set_verbose {
    ($Verbose) = @_;
}

sub add_logfh {
    @LogFH = uniqnum @LogFH, @_;
}

sub remove_logfh {
    my %fh = map +(0+$_, 1), @_;
    @LogFH = grep !$fh{0+$_}, @LogFH;
}

sub clear_logfh {
    @LogFH = ();
}

sub suspend_log {
    $Suspend ||= [];
}

sub resume_log {
    $Suspend or return;
    my $susp = $Suspend;
    undef $Suspend;
    msg @$_ for @$susp;
}

sub set_prefix {
    ($Prefix) = @_;
}

sub handle_sigs {
    $SIG{__WARN__}  = sub { msg WARN => $_[0] =~ s/\n\z//r };
    $SIG{__DIE__}   = sub { 
        die $_[0] unless defined $^S && !$^S;
        msg ERR => $_[0] =~ s/\n\z//r;
        die $_[0];
    };
}

END {
    if ($Suspend) {
        clear_logfh;
        add_logfh \*STDERR;
        warnx "App::Jacana::Log: unread suspended messages:";
        set_prefix "  ";
        resume_log;
    }
}

1;
