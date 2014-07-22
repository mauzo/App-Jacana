package App::Jacana::Has::Markup;

use Moo::Role;

with    qw/ MooX::Role::Copiable /;

use App::Jacana::Util::Types;

has text    => (
    is          => "rw",
    default     => "",
    copiable    => 1,
);

my @Styles = qw/ normal italic bold /;

has style   => (
    is          => "rw",
    default     => "normal",
    isa         => Enum[@Styles],
    copiable    => 1,
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
