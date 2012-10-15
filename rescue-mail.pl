#!/usr/bin/perl -w

use Modern::Perl;
use Mail::Box;
use File::Find;
use Carp;

#grab all the mbox files from ~/.icedove/*/*/..... and make their folders in ./Maildir and import the message
#my $start_dir =
#  '/home/sven/.icedove/j6dh73g0.default/ImapMail/mail.home.org.au/';
#  '/data/backups/mail_quiet/mail.home.org.au/';

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
    keep_dups => 0,
);
say 'Maildir is ' . $Maildir->type;
my $count = $Maildir->messages;
say 'Maildir has ' . $count;

foreach my $mboxdir (qw(
		/data/backups/mail_quiet/mail.home.org.au/
		/data/backups/mail_quiet/mail.home.org-1.au/
		/data/backups/mail_quiet/mail.home.org.au___BACKUP/
		/data/backups/mail_x61/mail.home.org.au/
		/data/backups/mail_x61/mail.home.org.au___BACKUP/
		/data/backups/mail_x61/mail.home.org-1.au/
		/data/backups/mail_x61/mail.home.org-2.au/
		/data/backups/mail_x61/mail.home.org-3.au/
		)) {

	next if (! -e $mboxdir);
	use File::Find;
	find(
    {
        #wanted  => \&process,
	wanted   => sub {process($mboxdir, $File::Find::name)},
        untaint => 1
    },
    $mboxdir
);
}

$Maildir->close();

sub process {
    my $start_dir = shift;
    my $file = shift;

    return if ( -d $file );
    return if ( $file =~ /(\.msf|\.dat|Trash)$/ );

    #return unless ( $file =~ /SPAM/ );
    #return unless ( $file =~ /Serial/ );
    #return unless ( $file =~ /Super/ );

    #say $file;
    import_mail($start_dir, $file);
}

sub import_mail {
    my $start_dir = shift;
    my $file = shift;

    $file =~ /$start_dir(.*)$/;
    #make the foldername the way dovecot wants
    my $folder_name = '.'.$1;
    $folder_name =~ s/\.sbd//g;
    $folder_name =~ s/\//./g;
    $folder_name =~ s/-[1-9]//g;
    say $folder_name;

    #TODO: consider extracting and using mbox subfolder_extension
    my $folder = $mgr->open( folder => $file, lock_type => 'NONE' );
    say $folder->type;
    my $count = $folder->messages;
    say $count;

    #$mgr->copyMessage( $Maildir, $folder->message(0));
    my $subfolder = $Maildir->openSubFolder($folder_name);
$count = $subfolder->messages;
say 'folder has ' . $count;

    #darn, when you call it twice it makes duplicates :/
    #plus, on the 331MB mbox i have, it uses >2GB ram and then gets killed by th eoom killer
    #$mgr->copyMessage( $subfolder, $_ ) for $folder->messages;
    foreach my $msg ($folder->messages) {
	next if ($subfolder->find($msg->messageId()));
	say $msg->messageId();
	
        $mgr->copyMessage( $subfolder, $msg);# if (!
    }

$count = $subfolder->messages;
say 'folder now has ' . $count;
    $subfolder->close();
    $folder->close();
}

1;
__DATA__
/data/backups/mail_quiet:
mail.home.org-1.au
mail.home.org-1.au.msf
mail.home.org.au
mail.home.org.au___BACKUP
mail.home.org.au.msf

/data/backups/mail_x61:
mail.home.org-1.au
mail.home.org-1.au.msf
mail.home.org-2.au
mail.home.org-2.au.msf
mail.home.org.au
mail.home.org.au___BACKUP
mail.home.org.au.msf
