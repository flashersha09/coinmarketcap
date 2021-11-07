package App::Plugin::Database;
use Mojo::Base 'Mojolicious::Plugin';

use Database;

sub register {
	my ($self, $app, $cfg) = @_;

	my %dbh;

	$app->helper(db => sub {
		$dbh{$$} ||= Database->new({
			dbname => $cfg->{name},
			dbhost => $cfg->{host},
			dbport => $cfg->{port},
			dbuser => $cfg->{user} || '',
			dbpass => $cfg->{password} || '',
		});
	});
}

1;