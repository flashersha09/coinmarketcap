package App::Controller::Coinmarketcap;
use Mojo::Base 'Mojolicious::Controller';

sub holla {
	my $c = shift;
	$c->render(json => {
		Holla =>\1
	});
}

sub currencies {
	my $c = shift;
	my $currencies = $c->model->currencies->get_list()->every(sub {
		my $self = shift;
		{
			id => $self->{'id'},
			symbol => $self->{'symbol'},
		}
	});
	$c->render(json => {
		cirrencies => $currencies
	});
}

sub rates {
	my $c = shift;
	my $opts = $c->opts;
	my $res = {};
	# $opts insert validator
	if ($opts) {
		my $currency = $c->currency( $opts->{'currency'} );
		if ($currency) {
			my $rates = $c->model->rates->get_list({
				currency_id => $currency->{'id'},
				update_rate_id => $c->db->select_query('update_rates', ['MAX(id)'])->first->{'max'},
			})->first;

			$res = {
				success => \1,
				rates => $rates,
			};
		}
		else {
			$res = {
				success => \0,
				message => 'Can not find currency',
			};
		}
	}
	else {
		$res = {
			succes => \0,
			message => 'Сan not currency id or symbol: /rates?currency=[id or symbol]',
		};
	}
	$c->render(json => $res);
}

sub pair {
	my $c = shift;
	my $opts = $c->opts;
	my $res = {};
	my ($currency_from, $currency_to);
	# $opts insert validator
	if ($opts) {
		$currency_from = $c->currency( $opts->{'from'} );
		$currency_to = $c->currency( $opts->{'to'} );

		if ( $currency_from && $currency_to ) {
			my $rates = $c->model->rates->get_list({
				currency_id => $currency_from->{'id'},
				update_rate_id => $c->db->select_query('update_rates', ['MAX(id)'])->first->{'max'},
			})->first;

			$res = {
				success => \1,
				pair => sprintf('%s-%s', $currency_from->{'symbol'}, $currency_to->{'symbol'}),
				rate => $rates->{'rates'}->{ $currency_to->{'symbol'} },
			};
		}
		else {
			$res = {
				success => \0,
				message => 'Can not find pair',
			};
		}
	}
	else {
		$res = {
			succes => \0,
			message => 'Сan not pair id or symbol: /pair?from=[id or symbol]&to=[id or symbol]',
		};
	}
	$c->render(json => $res);
}

1;
