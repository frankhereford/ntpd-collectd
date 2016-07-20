package Collectd::Plugins::NTP;

use strict;
no strict "subs";

use Collectd qw (:all);

my $host = `hostname -f`;
chomp $host;

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

Collectd::plugin_register(Collectd::TYPE_READ, "NTP", "ntpq_read");
 
1;
