package App::Plugin::Helpers;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;

	$app->helper(opts => sub {
		my ( $c, $data ) = @_;
		my $hash = $c->req->params->to_hash;
		return %{$hash} ? $hash : undef;
	});

	$app->helper(currency => sub {
		my $c = shift;
		my $where = shift;
		my ($id, $symbol, $currency);
		return undef unless $where;

		if ( $where =~/^\d+$/ ) {
			$id = $where;
		}
		else {
			$symbol = $where;
		}
		if ($id) {
			$currency = $c->model->currencies->get($id);
		}
		elsif ($symbol){
			$currency = $c->model->currencies->get_list({
				symbol =>  $symbol
			})->first;
		}
		return $currency;
	});

}

1;
