gitmks
=======================

Scripts that allow interface between a git repository and an mks project

INSTALL
=======================

To install simply unpack the gitmks scripts and update your git configuration to alias git mks and point it at the main gitmks script

$ git config --global --add alias.mks !sh [Path to gitmks.sh]/gitmks.sh

Now if you run git mks it should alias to the gitmks scripts






Commands
=======================
      init        <local path> initializes a git/MKS repository at the local location
      info        Displays the MKS repository information
      clean       cleans all ignored files out of working directory
      add         [MKS project] <local folder> [dev_path] initializes a git/MKS repository at the local location
      viewsandbox        opens a mks gui for each sanbox in the git project
      viewnonmembers        lists all non members in si project
      update      updates the mks remote for the given repository
      fetch       updates the mks remote for the given repository
      rebase      rebases the mks remote to the currently checked out branch

