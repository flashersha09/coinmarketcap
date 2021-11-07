package App;
use Mojo::Base 'Mojolicious';
use App::Router;
use constant EXPIRATION => 3600;

sub startup {
	my ($self) = @_;
	$self->_init_config;

	push @{$self->plugins->namespaces},  'App::Plugin';
	push @{$self->commands->namespaces}, 'App::Command';
	push @{$self->routes->namespaces},   'App::Controller';

	$self->_init_plugins;

	$self->secrets($self->config('secrets') or die "Did not secret");
	$self->sessions->default_expiration($self->config('session_expiration') //  EXPIRATION);

	$self->_init_hooks;
	$self->log( Mojo::Log->new( path => $self->config('logfiles')->{'app'} ) );

	App::Router->init($self);
}

sub _init_config {
	my ($self) = @_;
	$self->plugin(Config => { file => 'app.conf' });
	return;
}

sub _init_plugins {
	my ($self) = @_;
	$self->plugin(Database => $self->config('database') || {});
	$self->plugin('Helpers');
	$self->plugin('Model');
	return;
}

sub _init_hooks {
	my ($self) = @_;

	$self->hook(after_build_tx => sub {
		my ($tx, $app) = @_;
		$tx->res->headers->header('Access-Control-Allow-Origin' => '*');
		$tx->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
		$tx->res->headers->header('Access-Control-Max-Age' => 3600 );
		$tx->res->headers->header('Access-Control-Allow-aders' => 'Content-Type, Authorization, X-Requested-With');
	});
	return;
}

1;
