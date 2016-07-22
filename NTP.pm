package Collectd::Plugins::NTP;

use strict;
no strict "subs";
use Tie::DNS;

use Collectd qw (:all);
tie my %dns, 'Tie::DNS';

my $host = `hostname -f`;
chomp $host;

sub offset_read
  {
  my $cmd = 'ntpq -nc peers';
  open(my $ntpq, "-|", $cmd); 
  <$ntpq>;
  <$ntpq>;
  while (my $line = <$ntpq>)
    {
    my @data = split(/\s+/, $line);
    $data[8] += 0;
    next unless $data[8];
    $data[0] =~ /[\+\-\*](\d+\.\d+\.\d+\.\d+)/;
    my $ip = $1;
    my $ntp_data =
      {
      plugin => 'NTP',
      type_instance => ($dns{$ip} ? $dns{$ip} : $ip),
      type => 'ntp_offset',
      time => time,
      interval => plugin_get_interval(),
      host => $host,
      values => [ $data[8] ],
      };
    plugin_dispatch_values ($ntp_data);
    }
  # the trick will be to offer a cron job to clean up old stale servers you have not seen in a while
  close $ntpq;

  return 1;
  }

sub ntpq_read
  {
  my $cmd = '/usr/bin/ntpq -c sysinfo';
  open(my $ntpq, "-|", $cmd); 
  my %ntpq;
  <$ntpq>;
  while (my $line = <$ntpq>)
    {
    $line =~ /(.*?):\s+(.*)$/;
    my $key = $1;
    my $value = $2;
    print $key, ": ", $value, "\n";

    if ($key =~ /system jitter/)
      {
      my $ntp_data =
        {
        plugin => 'NTP',
        type_instance => 'System Jitter',
        type => 'ntp_values',
        time => time,
        interval => plugin_get_interval(),
        host => $host,
        values => [ $value ], 
        };
      plugin_dispatch_values ($ntp_data);
      }

    if ($key =~ /clock jitter/)
      {
      my $ntp_data =
        {
        plugin => 'NTP',
        type_instance => 'Clock Jitter',
        type => 'ntp_values',
        time => time,
        interval => plugin_get_interval(),
        host => $host,
        values => [ $value ], 
        };
      plugin_dispatch_values ($ntp_data);
      }
    if ($key =~ /clock wander/)
      {
      my $ntp_data =
        {
        plugin => 'NTP',
        #type_instance => 'Clock Wander',
        type => 'ntp_clock_wander',
        time => time,
        interval => plugin_get_interval(),
        host => $host,
        values => [ $value ], 
        };
      plugin_dispatch_values ($ntp_data);
      }




    }
  close($ntpq);

  return 1;
  }

sub read
  {
  ntpq_read();
  offset_read(); 
  return 1;
  }

Collectd::plugin_register(Collectd::TYPE_READ, "NTP", "read");
 
1;
