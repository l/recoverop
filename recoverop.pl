use Data::Dumper;

sub event_server_quit {
	my ($server, $msg) = @_;
	Irssi::print('event server quit');
	return;
}
Irssi::signal_add('server quit', 'event_server_quit');

sub is_debug {
	return 0;
#	return 1;
}

sub dprint {
	my $msg = shift;
	if (&is_debug) {
		Irssi::print($msg);
	}
	return;
}

sub is_alone {
	my $channel = shift;
	my @tmp = $channel->nicks;
	my $tmp = scalar @tmp;
	&dprint($tmp);
	if ($tmp == 2) {
		return 1;
	} else {
		return 0;
	}
}

sub is_channelop {
	my $channel = shift;
	&dprint(Dumper($channel));
	return $channel->{chanop};
}

sub is_yourpart {
	my $server = shift;
	my $nick = shift;
	return $nick eq $server->{nick};
}

sub is_restricted {
	my $server = shift;
	return $server->{usermode} =~ m/r/;
}

sub recoverop_check {
	my ($channel_obj, $nick) = @_;
	my $server_obj = $channel_obj->{server};
#	&dprint(Dumper($channel_obj));
	if (&is_restricted($server_obj)) {
		&dprint("Your mode is restricted mode. Can't get op.");
	} elsif (&is_yourpart($server_obj, $nick)) {
		&dprint("This part is your part.");
	} else {
		if (&is_channelop($channel_obj)) {
			&dprint("You already have op.");
		} elsif (!&is_alone($channel_obj)) {
			&dprint("You are not all alone. Can't recover op.");
		} else {
			return 1;
		}
	}
	return 0;

}

sub recoverop_main {
	my $channel_obj = shift;
	&dprint("Try to get op.");
	$channel_obj->command("cycle");
	return;
}

sub recoverop {
	my ($channel_obj, $nick) = @_;
	if (&recoverop_check($channel_obj, $nick)) {
		&recoverop_main($channel_obj);
	}
	&dprint($channel_obj->{server}->{tag});
	&dprint($nick);
	&dprint($channel_obj->{name});
	return;
}

sub event_message_part {
	my ($server_obj, $channel, $nick, $address, $reason) = @_;
	my $channel_obj = $server_obj->channel_find($channel);
	&recoverop($channel_obj, $nick);
	return;
}
Irssi::signal_add('message part', 'event_message_part');

sub event_message_quit {
	my ($server_obj, $nick, $address, $reason) = @_;
	foreach my $channel_obj ($server_obj->channels()) {
		if ($channel_obj->nick_find($nick)) {
			&recoverop($channel_obj, $nick);
		}
	}
	return;
}
Irssi::signal_add('message quit', 'event_message_quit');
