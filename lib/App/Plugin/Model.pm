package App::Plugin::Model;
use Mojo::Base 'Mojolicious::Plugin';
use App::Module::Model;
use Mojo::Util qw(camelize decamelize);
use Carp qw(confess);
use FindBin;

my @models;

BEGIN {
	use lib "$FindBin::Bin/lib/App/Model";
	my $dir = "$FindBin::Bin/lib/App/Model";
	find($dir);
	for my $module ( map {$_ =~s{\.pm}{}; $_ =~s{/}{::}; $_ = "App::Model::" . $_; $_ } @models) {
		eval "require ${module}" or confess "Can't require package $module: $@";
		$module->import();
	}

	sub find {
		my $path = shift;
		for my $item (<$path/*>) {
			if(-d $item) {
				find($item);
			}
			else {
				$item=~s/$dir\///i;
				push @models, $item if $item=~/\.pm$/i;
			}
		}
	}
}

sub register {
	my ($self, $app) = @_;

	my $models = App::Module::Model->new();
	for my $model (@models) {
		my $value = $model->new();
		$value->attr(app => sub {$app});
		$model=~s/App::Model:://;
		my $key = $self->model_name_normalize($model);
		$models->attr($key => sub {$value});
	}

	$app->helper(model => sub {
		my $c = shift;
		my $name = shift;
		return $models unless $name;
		return $models->$name;
	});

}

sub model_name_normalize {
	my $c = shift;
	my $name = shift;
	return undef unless $name;
	$name = decamelize($name);
	$name =~s {-}{_}g;
	$name;
}

1;