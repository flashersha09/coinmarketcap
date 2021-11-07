package App::Model::Currencies;
use Mojo::Base 'App::Model';

has columns => sub { [qw/
	id symbol ctime
/] };

sub save {
	my $self = shift;
	my $currency_code = shift;
	my $id;
	return undef unless $currency_code;

	my $currency = $self->get_list({ symbol => $currency_code })->first;
	if ($currency) {
		$id = $currency->{'id'};
	}
	else {
		$id = $self->create( { symbol => $currency_code, ctime => '\NOW()' } );
	}
	return $id;
}

1;
