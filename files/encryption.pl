#!/usr/bin/env perl
use strict;
use warnings;
use YAML::XS qw(LoadFile DumpFile);
use File::Copy qw(copy);
use POSIX qw(strftime);

my $manifest = shift || '/etc/kubernetes/manifests/kube-apiserver.yaml';
my $enc_flag        = '--encryption-provider-config=/etc/kubernetes/enc/enc.yaml';
my $enc_volume_name = 'enc';
my $enc_mount_path  = '/etc/kubernetes/enc';
my $enc_host_path   = '/etc/kubernetes/enc';
my $enc_type        = 'DirectoryOrCreate';

die "Manifest not found: $manifest\n" unless -f $manifest;

my $ts = strftime('%Y%m%d%H%M%S', localtime);
my $backup = "/root/$manifest.$ts.bak";
copy($manifest, $backup) or die "Failed to back up manifest to $backup: $!";

my $doc = LoadFile($manifest);
die "Manifest is not a Pod (kind!=Pod)\n" unless ref($doc) eq 'HASH' && ($doc->{kind}||'') eq 'Pod';

sub _has_enc_flag {
    my ($ary) = @_;
    return 0 unless $ary && ref($ary) eq 'ARRAY';
    for my $i (0..$#$ary) {
        my $v = $ary->[$i] // '';
        return 1 if $v =~ /^--encryption-provider-config(?:=|$)/;
        if ($v eq '--encryption-provider-config' && defined $ary->[$i+1] && $ary->[$i+1] ne '') {
            return 1;
        }
    }
    return 0;
}

sub _ensure_enc_flag {
    my ($cmd, $args) = @_;
    if ($cmd && ref($cmd) eq 'ARRAY' && @$cmd) {
        if (_has_enc_flag($cmd)) {
        } else {
            push @$cmd, $enc_flag;
        }
    } elsif ($args && ref($args) eq 'ARRAY') {
        _has_enc_flag($args) ? 1 : push(@$args, $enc_flag);
    } else {
        $doc->{spec}->{containers}->[0]->{command} = ['kube-apiserver', $enc_flag];
    }
}

sub _ensure_volume_mount {
    my ($mounts) = @_;
    $mounts ||= [];
    my $found = 0;
    for my $m (@$mounts) {
        next unless ref($m) eq 'HASH';
        if (($m->{name}||'') eq $enc_volume_name) {
            $m->{mountPath} = $enc_mount_path;
            $m->{readOnly}  = \1;
            $found = 1;
            last;
        }
    }
    if (!$found) {
        push @$mounts, {
            name      => $enc_volume_name,
            mountPath => $enc_mount_path,
            readOnly  => \1,
        };
    }
    return $mounts;
}

sub _ensure_volume {
    my ($vols) = @_;
    $vols ||= [];
    my $found = 0;
    for my $v (@$vols) {
        next unless ref($v) eq 'HASH';
        if (($v->{name}||'') eq $enc_volume_name) {
            $v->{hostPath} ||= {};
            $v->{hostPath}->{path} = $enc_host_path;
            $v->{hostPath}->{type} = $enc_type;
            $found = 1;
            last;
        }
    }
    if (!$found) {
        push @$vols, {
            name     => $enc_volume_name,
            hostPath => { path => $enc_host_path, type => $enc_type },
        };
    }
    return $vols;
}

my $containers = $doc->{spec}->{containers}
  or die "Manifest missing spec.containers\n";
die "spec.containers must be an array\n" unless ref($containers) eq 'ARRAY' && @$containers;

my $idx = -1;
for my $i (0..$#$containers) {
    my $c = $containers->[$i];
    if (($c->{name}||'') eq 'kube-apiserver') { $idx = $i; last; }
}

if ($idx < 0) {
    for my $i (0..$#$containers) {
        my $c = $containers->[$i];
        my $in_cmd = ($c->{command} && grep { defined && /kube-apiserver$/ } @{$c->{command}});
        my $in_args = ($c->{args} && grep { defined && /kube-apiserver$/ } @{$c->{args}});
        if ($in_cmd || $in_args || (($c->{image}||'') =~ /kube-apiserver/)) { $idx = $i; last; }
    }
}
die "Could not locate kube-apiserver container\n" if $idx < 0;

my $c = $containers->[$idx];

_ensure_enc_flag($c->{command}, $c->{args});
$c->{volumeMounts} = _ensure_volume_mount($c->{volumeMounts});
$doc->{spec}->{volumes} = _ensure_volume($doc->{spec}->{volumes});

DumpFile($manifest, $doc) or die "Failed to write updated manifest\n";

print "Updated $manifest (backup: $backup)\n";
