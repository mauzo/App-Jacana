package App::Jacana::Log;

use 5.012;
use warnings;

use App::Jacana::Log::Logger;

use Carp;
use Data::Dumper;
use Exporter    qw/import/;
use Fcntl;
use File::Path  qw/make_path/;
use File::Slurp qw/read_dir/;
use List::Util  qw/uniqnum/;
use POSIX       qw/strftime/;

our @EXPORT = qw/msg msgf/;

my @Loggers;
my $Suspend;
my $Prefix = "";

sub suspend_log;
sub add_logger;
sub set_prefix;

sub pp {
    Data::Dumper->new([$_[0]])->Terse(1)->Sparseseen(1)
        ->Sortkeys(1)->Useqq(1)->Quotekeys(0)->Maxdepth(2)->Dump
        =~ s/\n\z//r;
}

sub warnx { say STDERR map +(ref ? pp $_ : $_), @_ }

sub msg {
    my ($fac, @msg) = @_;

    @Loggers or suspend_log;
    $Suspend and push(@$Suspend, [$fac, @msg]), return;

    my $msg = join " ", map +(ref ? pp $_ : $_), @msg;
    $_->msg($fac, "$Prefix\[$fac] $msg") for @Loggers;
}

sub msgf {
    my ($fac, $fmt, @args) = @_;
    msg $fac, sprintf $fmt, @args;
}

sub open_logfile {
    my $logdir  = "$ENV{HOME}/.local/share/morrow.me.uk/Jacana/logs";
    make_path $logdir;

    my @old = sort +read_dir $logdir;
    if (@old > 4) {
        splice @old, -4;
        unlink "$logdir/$_" for @old;
    }

    my $logfile = strftime "%Y-%m-%d-%H.%M.%S.log", localtime;
    my $logpath = "$logdir/$logfile";

    sysopen my $LOG, $logpath, O_WRONLY|O_CREAT|O_EXCL
        or die "Can't open '$logpath': $!\n";
    add_logger $LOG, 1;

    warnx "App::Jacana: logging to '$logpath'";

    return $logpath;
}

sub add_logger {
    my ($FH, @levels) = @_;

    my $log = App::Jacana::Log::Logger->new(
        logfh   => $FH,
        (@levels == 1 && $levels[0] eq "1"
            ? (verbose  => 1)
            : (active   => +{ map +($_, 1), @levels, qw/ERR WARN/ })
        ),
    );
    push @Loggers, $log;

    return $log;
}

sub remove_logger {
    my ($log) = @_;
    @Loggers = grep $_ != $log, @Loggers;
}

sub clear_loggers {
    @Loggers = ();
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
        clear_loggers;
        add_logger \*STDERR, 1;
        warnx "App::Jacana::Log: unread suspended messages:";
        set_prefix "  ";
        resume_log;
    }
}

1;
