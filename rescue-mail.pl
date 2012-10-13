#!/usr/bin/perl -w

use Modern::Perl;
use Mail::Box;
use File::Find;
use Carp;

#grab all the mbox files from ~/.icedove/*/*/..... and make their folders in ./Maildir and import the messages
my $start_dir =
#  '/home/sven/.icedove/j6dh73g0.default/ImapMail/mail.home.org.au/';
  '/data/backups/mail_quiet/mail.home.org.au/';

unlink('Maildir.lock');    #i'm developing

use Mail::Box::Manager;
my $mgr     = Mail::Box::Manager->new;
my $Maildir = $mgr->open(
    #folder => 'Maildir',  # what if it dies on relative paths?
    folder=>'/home/sven/src/Mail-Box/Maildir',
    create => 1,
    access => 'rw',
    type   => 'Mail::Box::Maildir',
    #accept_new=>0,
);
say 'Maildir is ' . $Maildir->type;
my $count = $Maildir->messages;
say 'Maildir has ' . $count;

#exit;

use File::Find;
find(
    {
        wanted  => \&process,
        untaint => 1
    },
    $start_dir
);

$Maildir->close();

sub process {
    return if ( -d $File::Find::name );
    return if ( $File::Find::name =~ /(\.msf|\.dat|Trash)$/ );

    #return unless ( $File::Find::name =~ /SPAM/ );

    #say $File::Find::name;
    import_mail($File::Find::name);
}

sub import_mail {
    my $file = shift;

    $file =~ /$start_dir(.*?)(-[1-9])?$/;
    #make the foldername the way dovecot wants
    my $folder_name = '.'.$1;
    $folder_name =~ s/\.sbd//g;
    $folder_name =~ s/\//./g;
    say $folder_name;

    #TODO: consider extracting and using mbox subfolder_extension
    my $folder = $mgr->open( folder => $File::Find::name, lock_type => 'NONE' );
    say $folder->type;
    my $count = $folder->messages;
    say $count;

    #$mgr->copyMessage( $Maildir, $folder->message(0));
    my $subfolder = $Maildir->openSubFolder($folder_name);

    #darn, when you call it twice it makes duplicates :/
    #plus, on the 331MB mbox i have, it uses >2GB ram and then gets killed by th eoom killer
    $mgr->copyMessage( $subfolder, $_ ) for $folder->messages;

    $subfolder->close();
    $folder->close();
}
