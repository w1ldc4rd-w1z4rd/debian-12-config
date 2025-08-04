#!/usr/bin/env perl

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Debian 12 Installer (Non Prod)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#          _nnnn_
#         dGGGGMMb
#        @p~qp~~qMb
#        M|@||@) M|
#        @,----.JM|
#       JS^\__/  qKL
#      dZP        qKRb
#     dZP          qKKb
#    fZP            SMMb
#    HZM            MMMM
#    FqM            MMMM
#  __| ".        |\dS"qML
#  |    `.       | `' \Zq
# _)      \.___.,|     .'
# \____   )MMMMMP|   .'
#      `-'       `--' 
#
# Debian 12 Setup
# By: Wildcard Wizard (v2025-08-04)
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Pragmas
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use v5.14;
use utf8;

use Term::ANSIColor qw(:constants);
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Environment Setup
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set UTF-8 locale for this script's execution
$ENV{LANG} = 'en_US.UTF-8';
$ENV{LC_ALL} = 'en_US.UTF-8';

# Ensure proper PATH
$ENV{PATH} = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ENV{HOME}/code";

# Set non-interactive for all child processes
$ENV{DEBIAN_FRONTEND} = 'noninteractive';
$ENV{NEEDRESTART_MODE} = 'a';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Globals
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$|++;

my $db = [];
my ($cata, $num) = (undef, -1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create DB of commands
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COMMANDS: while (<DATA>)
{
	chomp;
	my $line = $_;
	next COMMANDS if $line =~ m~^$~;
	
	if (m{ ^\#\ ~{33}\ ([A-Z]+)$ }x)
	{
		my $cata_cur = $1;
		
		$cata = $cata_cur;
		$num = $num == -1 ? 0 : ++$num;
		next COMMANDS;
	}
	
	next if $line =~ m{^#};
	
	do {
		msg( "No catagory found so bailing!", 'RED' );
		exit 69;
	} unless $cata;
	
	push @{$db->[$num]->{$cata}}, $line;
} 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Main Menu
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MENU:
{
	clear();
	my $m = 0;
	border();
	say q(Main Menu - [#], [#a]utorun, [q]uit);
	border(); 
	map { say $m, ' - ' , "@{[keys %{$db->[$m]}]}" =~ s~^.\K.+~lc $&~er; $m++ } @{$db};
	border();
	print q(> );
	chomp( my $choice = <STDIN> ); 
	
	goto MENU if $choice =~ m~^$~;
	
	do {
		msg( 'Bye bye time!', 'RED' ); 
		exit 0;
	} if $choice =~ m~^Q$~i;
	
	if ($db->[$choice])
	{
		if ($choice =~ m~^\d+$~)
		{ 
			cmd_runner($choice, 1) 
		}
		elsif ($choice =~ m~^\d+a$~i)
		{ 
			cmd_runner($choice) 
		}
		else
		{ 
			goto MENU 
		}
	}
	else
	{
		goto MENU
	}
} 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Command(s) Execute Sub
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub cmd_runner
{
	my $pos = shift;
	my $onetime = shift // undef;
	
	RUN: for my $key (keys @{$db})
	{
		next RUN if $pos != $key;
		$pos++;
		my ($run) = keys %{$db->[$key]};
		msg( "$run: running commands...", 'BOLD YELLOW');
		map
		{
			run( $_ );
			
		} @{ $db->[$key]->{$run} };
		
		if ($onetime)
		{
			msg('All done! Bye bye!');
			exit 0;
		}
	} 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Support Subs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Clear screen
sub clear
{
    # Clears the entire screen
    print "\033[2J";    
    
    # Moves the cursor to the top-left corner 
    print "\033[H";        
}

# Typewriter
sub t
{
    my $text = shift;
 
    $text =~ s~.~
        do 
        {
            # small random delay per character
            select(undef, undef, undef, rand(0.01)); 
            print $&;                                
        }
    ~sge;
}

# Status message
sub msg
{
    chomp( my $msg = shift );
    chomp( my $color = shift // q|GREEN| );
    print q|> |;
    eval qq{print ${color} };
    t( $msg );
    say RESET q||;
}

# Run a program
sub run
{
    my $cmd = shift;
    msg( $cmd, 'GREEN' );
    eval { system $cmd };
   
    if ($?)
    {
        my $exit_code = $? >> 8;
        msg( "Command failed: ${exit_code}", 'RED' );
        exit $exit_code;
    }
}

# Print border
sub border
{
    my $num = shift // 42;
    say q{-} x $num;
}

# Data Dumper
sub dd
{
    say Dumper shift;
}

__END__

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SUDO

# Setup non-password for sudo (Dangerous for production!)
echo $USER | perl -nle 'print qq~${_} ALL=(ALL) NOPASSWD:ALL~' | sudo tee -a /etc/sudoers >/dev/null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ UPDATES

# Update package list
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

# Upgrade packages
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Perform distribution upgrade
# sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LOCALES

# Install the locales package which contains locale generation tools
sudo apt-get install -y locales

# Use sed to find and uncomment the en_US.UTF-8 line in locale.gen
sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen

# Generate the locale files based on what's enabled in /etc/locale.gen
sudo locale-gen

# Write LANG setting to /etc/default/locale
echo 'LANG="en_US.UTF-8"' | sudo tee /etc/default/locale

# Append LC_ALL setting to /etc/default/locale
echo 'LC_ALL="en_US.UTF-8"' | sudo tee -a /etc/default/locale

# Update the system locale settings based on the values we just set
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Display current locale settings to verify everything is configured
locale

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ DIRS

mkdir -p $HOME/temp
mkdir -p $HOME/git
mkdir -p $HOME/code
# Create necessary directories for backup, swap, and undo files
mkdir -p $HOME/.vim/tmp

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ UFW

# UFW Configuration
sudo apt install ufw -y
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
yes | sudo ufw enable
sudo ufw status verbose

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ BASHRC

# Append lines to .bashrc individually
echo "" | tee -a $HOME/.bashrc >/dev/null

# Set vi mode for command line editing
echo "# Set vi mode for command line editing" | tee -a $HOME/.bashrc >/dev/null
echo "set -o vi" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Export Environment Variables
echo "# Export Environment Variables" | tee -a $HOME/.bashrc >/dev/null
echo "# Set default editor as Vim" | tee -a $HOME/.bashrc >/dev/null
echo "export VISUAL=/usr/bin/vim" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Customize the command prompt
echo "# Customize the command prompt" | tee -a $HOME/.bashrc >/dev/null
echo "export PS1='\w> '" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Add custom path to PATH
echo "# Add custom path to PATH" | tee -a $HOME/.bashrc >/dev/null
echo "export PATH=\$HOME/code:\$PATH" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias Commands
echo "# Alias Commands" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias for clearing the screen
echo "# Alias for clearing the screen" | tee -a $HOME/.bashrc >/dev/null
echo "alias c='clear'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias for listing files in long format with human-readable sizes
echo "# Alias for listing files in long format with human-readable sizes" | tee -a $HOME/.bashrc >/dev/null
echo "alias l='clear && ls -lha'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias to edit and reload .bashrc
echo "# Alias to edit and reload .bashrc" | tee -a $HOME/.bashrc >/dev/null
echo "alias bed='vi \${HOME}/.bashrc && source \${HOME}/.bashrc && clear'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias to view command history
echo "# Alias to view command history" | tee -a $HOME/.bashrc >/dev/null
echo "alias h='history'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias to edit Apache config and restart Apache server
echo "# Alias to edit Apache config and restart Apache server" | tee -a $HOME/.bashrc >/dev/null
echo "alias web='sudo vi /etc/apache2/sites-available/web.conf && sudo service apache2 restart'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias to change directory to /var/www/
echo "# Alias to change directory to /var/www/" | tee -a $HOME/.bashrc >/dev/null
echo "alias www='cd /var/www/'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias for updating and upgrading the system
echo "# Alias for updating and upgrading the system" | tee -a $HOME/.bashrc >/dev/null
echo "alias up='sudo apt update -y && sudo apt upgrade -y'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias for setting up SSL with certbot and restarting Apache
echo "# Alias for setting up SSL with certbot and restarting Apache" | tee -a $HOME/.bashrc >/dev/null
echo "alias ssl='sudo certbot --apache && sudo service apache2 restart'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias for fail2ban: to check SSH login attempts, remote logins, and active sessions in a single line
echo "# Alias to check SSH login attempts, remote logins, and active sessions in a single line" | tee -a $HOME/.bashrc >/dev/null
echo "alias w='clear && sudo fail2ban-client status sshd | grep -v Banned && printf \"*** REMOTE LOGINS ***\\n\" && lastlog | grep -v \"***Never\" && printf \"*** STILL LOGGED IN ***\\n\" && last | grep -i still'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# Alias for copying files with rsync
echo "# Alias for copying files with rsync" | tee -a $HOME/.bashrc >/dev/null
echo "alias cpr='rsync --archive --verbose --update --progress'" | tee -a $HOME/.bashrc >/dev/null
echo "" | tee -a $HOME/.bashrc >/dev/null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ VIMRC

# Adding useful defaults to .vimrc
echo "set number" | tee -a $HOME/.vimrc >/dev/null
echo "syntax on" | tee -a $HOME/.vimrc >/dev/null
echo "set showcmd" | tee -a $HOME/.vimrc >/dev/null
echo "set cursorline" | tee -a $HOME/.vimrc >/dev/null
echo "set wildmenu" | tee -a $HOME/.vimrc >/dev/null
echo "set expandtab" | tee -a $HOME/.vimrc >/dev/null
echo "set tabstop=4" | tee -a $HOME/.vimrc >/dev/null
echo "set shiftwidth=4" | tee -a $HOME/.vimrc >/dev/null
echo "set autoindent" | tee -a $HOME/.vimrc >/dev/null
echo "set smartindent" | tee -a $HOME/.vimrc >/dev/null
echo "set background=dark" | tee -a $HOME/.vimrc >/dev/null
echo "set incsearch" | tee -a $HOME/.vimrc >/dev/null
echo "set hlsearch" | tee -a $HOME/.vimrc >/dev/null
echo "set ignorecase" | tee -a $HOME/.vimrc >/dev/null
echo "set smartcase" | tee -a $HOME/.vimrc >/dev/null
echo "set clipboard=unnamedplus" | tee -a $HOME/.vimrc >/dev/null
echo "set splitright" | tee -a $HOME/.vimrc >/dev/null
echo "set splitbelow" | tee -a $HOME/.vimrc >/dev/null
echo "set mouse=a" | tee -a $HOME/.vimrc >/dev/null
echo "set backupdir=$HOME/.vim/tmp,." | tee -a $HOME/.vimrc >/dev/null
echo "set directory=$HOME/.vim/tmp,." | tee -a $HOME/.vimrc >/dev/null
echo "set undodir=$HOME/.vim/tmp,." | tee -a $HOME/.vimrc >/dev/null
echo "set undofile" | tee -a $HOME/.vimrc >/dev/null
echo "set hidden" | tee -a $HOME/.vimrc >/dev/null
echo "set ruler" | tee -a $HOME/.vimrc >/dev/null
echo "set relativenumber" | tee -a $HOME/.vimrc >/dev/null
echo "set laststatus=2" | tee -a $HOME/.vimrc >/dev/null
echo "set statusline=%f%m%r%h%w[%{&ff},%Y][%l/%L,%c][%p%%]" | tee -a $HOME/.vimrc >/dev/null
echo "filetype plugin on" | tee -a $HOME/.vimrc >/dev/null
echo "filetype indent on" | tee -a $HOME/.vimrc >/dev/null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ APT

# Install CA certificates for SSL/TLS
sudo apt install -y ca-certificates

# Install build-essential package (includes gcc, g++, and make)
sudo apt install -y build-essential

# Install make utility separately (although it is included in build-essential)
sudo apt install -y make

# Install neofetch, a system information tool
sudo apt install -y neofetch

# Install ufw (Uncomplicated Firewall) for managing firewall rules
sudo apt install -y ufw

# Install vim text editor
sudo apt install -y vim

# Install git version control system
sudo apt install -y git

# Install rsync for file synchronization and transfer
sudo apt install -y rsync

# Install curl, a tool for transferring data using various protocols
sudo apt install -y curl

# Install wget, a utility for retrieving files using HTTP, HTTPS, and FTP
sudo apt install -y wget

# Install ack-grep, a grep-like source code search tool
sudo apt install -y ack-grep

# Install gpm (General Purpose Mouse) for console mouse support
sudo apt install -y gpm

# Install pcregrep, a grep that understands Perl Compatible Regular Expressions
sudo apt install -y pcregrep

# Install lynx, a text-based web browser
sudo apt install -y lynx

# Install htop, an interactive process viewer
sudo apt install -y htop

# Install ssh client and server
sudo apt install -y ssh

# Install net-tools (includes ifconfig, netstat, route, etc.)
sudo apt install -y net-tools

# Install ifupdown for network interface management
sudo apt install -y ifupdown

# Install unzip utility for extracting zip archives
sudo apt install -y unzip

# Install screen, a terminal multiplexer
sudo apt install -y screen

# Install tmux, another terminal multiplexer
sudo apt install -y tmux

# Install thermald, the Linux thermal daemon (commented out)
# sudo apt install -y thermald

# Archive software
# Install xz-utils for XZ format compression and decompression
sudo apt install -y xz-utils

# Install tar for creating and extracting tar archives
sudo apt install -y tar

# Debian Extras Installer
# Install youtube-dl, a YouTube downloader (Deprecated)
# sudo apt install -y youtube-dl

# Install xdotool for simulating keyboard/mouse input
sudo apt install -y xdotool

# Install minimodem, a software audio FSK modem
sudo apt install -y minimodem

# Install zbar-tools for reading barcodes from various sources
sudo apt install -y zbar-tools

# Install qrencode for generating QR codes
sudo apt install -y qrencode

# Install sox, the Swiss Army knife of sound processing programs
sudo apt install -y sox

# Install ffmpeg for audio and video processing
sudo apt install -y ffmpeg

# Install ImageMagick for image manipulation
sudo apt install -y imagemagick

# Install zenity for creating GUI dialog boxes in shell scripts
sudo apt install -y zenity

# Install dialog for creating text-based user interfaces
sudo apt install -y dialog

# Install expect for automating interactive applications
sudo apt install -y expect

# Install yad (Yet Another Dialog) for creating GUI dialog boxes
sudo apt install -y yad

# Install mc (Midnight Commander), a text-based file manager
sudo apt install -y mc

# Install ranger, another text-based file manager
sudo apt install -y ranger

# Install genisoimage for creating ISO 9660 filesystem images
sudo apt install -y genisoimage

# Debian GUI software
# Install Kate, a text editor for KDE
sudo apt install -y kate

# Install psensor, a graphical hardware temperature monitor
sudo apt install -y psensor

# Install Perl and related tools
sudo apt install -y cpanminus

# Libraries
sudo apt install -y libpcre3
sudo apt install -y libpcre3-dev
sudo apt-get install zlib1g-dev -y
sudo apt-get install libssl-dev -y
sudo apt install libperl-dev -y

# Install Perl modules using cpanm (system-wide)
sudo cpanm Mojolicious
sudo cpanm IO::All
sudo cpanm Net::SMTP::SSL
sudo cpanm Getopt::Long

# Remove unnecessary packages
sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y

# Clean up package cache
sudo DEBIAN_FRONTEND=noninteractive apt-get clean
