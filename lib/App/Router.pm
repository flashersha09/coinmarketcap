package App::Router;

use Mojo::Base -base;

sub init {
	my ($class, $app) = @_;

	my $router = $app->routes;

	my $r = $router->under('/');
	$r->any('')->to(controller => 'Coinmarketcap', action => 'holla');
	$r->get('/currencies')->to(controller => 'Coinmarketcap', action => 'currencies');
	$r->get('/rates')->to(controller => 'Coinmarketcap', action => 'rates');
	$r->get('/pair')->to(controller => 'Coinmarketcap', action => 'pair');

	return $router;
}

1;
