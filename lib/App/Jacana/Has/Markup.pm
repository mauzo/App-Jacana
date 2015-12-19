package App::Jacana::Has::Markup;

use Moose::Role;
use MooseX::Copiable;

has text    => (
    is          => "rw",
    traits      => [qw/Copiable/],
    default     => "",
);

my @Styles = qw/ normal italic bold /;

has style   => (
    is          => "rw",
    traits      => [qw/Copiable/],
    default     => "normal",
    #isa         => Enum[@Styles],
);

sub markup_rx {
    my $style = join "|", @Styles;
    qr( " (?<plain>[^"]*) "
        | \\markup \s* \{ \s* (?:
            (?<text> [^\\{}]* )
            | \\ (?<style> $style ) \s* \{
                (?<text> [^\\{}]* ) 
            \s* \}
        ) \s* \}
    )x;
}

sub markup_from_lily {
    my ($self, %n) = @_;
    $n{plain} and return (text => $n{plain});
    my @a = (text => $n{text} =~ s/^\s+|\s+$//gr);
    $n{style} and push @a, (style => $n{style});
    return @a;
}

sub markup_to_lily {
    my ($self) = @_;

    my $text = $self->text;
    my $style = $self->style;

    $style eq "normal" and return qq{"$text"};
    return "\\markup { \\$style { $text } }";
}

1;
