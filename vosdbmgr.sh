#!/bin/bash --norc
#  Backup and/or restore the PostgreSQL VosDB database.
#
#  To save the current VOS DB into a directory called 'backups':
#     > docker run -it --rm --name vosdbmgr --network vos_net -v ${PWD}/backups:/backups vosdbmgr
#
#  To restore (fill or replace) the current VOS DB with a previous backup
#     > docker run -it --rm --name vosdbmgr --network vos_net -v ${PWD}/backups:/backups vosdbmgr \
#       -c restore -f vos.sql
#
#  Written by: Tom Hicks. 12/9/2019.
#  Last Modified: Must save & restore as superuser.
#

# use or initialize standard PostgreSQL environment variables:
export PGDATABASE=${PGDATABASE:-vos}
export PGHOST=${PGHOST:-pgdb}
export PGPASSFILE=${PGPASSFILE:-.pgpass}
export PGPORT=${PGPORT:-5432}
export PGUSER=${PGUSER:-postgres}


# internal variables or script argument variables:
COMMAND=
BACKUP_DIR=/backups
DEBUG=0
DUMPFILE=vos
VERBOSE=0


Usage () {
    echo ""
    echo "Usage: $0 [-h] -c save [-f filename]  [-v | --debug]"
    echo "         OR"
    echo "       $0 [-h] -c restore -f filepath  [-v | --debug]"
    echo "where:"
    echo "    -h, --help          - print this help message and exit"
    echo "    -c, --cmd command   - required action: 'save' or 'restore'"
    echo "    -f, --file filename - for 'save': optional file name of the file to be created [default: vos]"
    echo "    -f, --file filepath - for 'restore': required file path of the file to restore from"
    echo "    -v, --verbose       - provide more information during run [default: not verbose]"
    echo "    --debug             - show additional debugging information"
    echo ""
}

# test for too few arguments or the help argument
if [ $# -lt 2 -o "$1" = "-h" -o "$1" = "--help" ]; then
  Usage
  exit 1
fi

# parse the script arguments:
while [ $# -gt 0 ]; do
    case "$1" in
        "-h"|"--help") Usage
                       exit 1
                       ;;
        "-c"|"--cmd") shift
                      COMMAND=${1:-save}
                      ;;
        "-f"|"--file") shift
                       DUMPFILE=${1:-vos}
                       ;;
        "-v"|"--verbose") VERBOSE=1
                          ;;
        "--debug") DEBUG=1
                   VERBOSE=1
                   ;;
        -*) echo "ERROR: Unknown optional argument: $1"
           Usage
           exit 2
           ;;
    esac
    shift
done


# sanity tests for the script arguments:
#

# test for the command argument
c1=`echo $COMMAND | cut -c1`
if [ -z "$COMMAND" -o -z "$c1" -o "$c1" = "-" ]; then
    echo "ERROR at '$COMMAND': The command argument is required and may not begin with '-'."
    echo "      Did you forgot to specify a command after the -c or --cmd flag?"
    Usage
    exit 10
fi

# check the command argument for validity
if [ "$COMMAND" != "save" -a "$COMMAND" != "restore" ]; then
    echo "ERROR: Command must be one of 'save' or 'restore', not '$COMMAND'"
    Usage
    exit 11
fi


# test for the dump file argument; a filename for 'save' but a path for 'restore'
f1=`echo $DUMPFILE | cut -c1`
if [ -z "$DUMPFILE" -o -z "$f1" -o "$f1" = "-" ]; then
    if [ "$COMMAND" = "save" ]; then
        echo "ERROR at '$DUMPFILE': The save filename is required and may not begin with '-'."
        echo "       Did you forgot to specify a filename after the -f or --file flag?"
    else
        echo "ERROR at '$DUMPFILE': The restore file path is required and may not begin with '-'."
        echo "       Did you forgot to specify a file path after the -f or --file flag?"
    fi
    Usage
    exit 20
fi


# print variables for debugging:
if [ $DEBUG -eq 1 ]; then
    echo "------------------------------------------------------------"
    echo "PostgreSQL Environment Variables:"
    echo "  PGDATABASE = $PGDATABASE"
    echo "  PGHOST     = $PGHOST"
    echo "  PGPASSFILE = $PGPASSFILE"
    echo "  PGPORT     = $PGPORT"
    echo "  PGUSER     = $PGUSER"
    echo ""
    echo "Command Line Arguments:"
    echo "  COMMAND    = $COMMAND"
    echo "  DUMPFILE   = $DUMPFILE"
    echo "  VERBOSE    = $VERBOSE"
    echo "  DEBUG      = $DEBUG"
    echo "------------------------------------------------------------"
fi


# Do the actual backup or restore work
if [ "$COMMAND" = "save" ]; then
    ftime=`date +%y-%m-%d_%H.%M`
    bname=`basename $DUMPFILE .sql`
    fname="${bname}_${ftime}.sql"
    fpath="${BACKUP_DIR}/${fname}"
    if [ $DEBUG -eq 1 ]; then
        echo "Save action variables:"
        echo "  DUMPFILE = $DUMPFILE"
        echo "  basename = $bname"
        echo "  fname    = $fname"
        echo "  fpath    = $fpath"
        echo "------------------------------------------------------------"
    fi

    # uses environment variables for PGHOST, PGPORT, PGUSER
    if [ $VERBOSE -eq 1 ]; then
        echo "Saving the VOS database to ${fname} ..."
    fi

    # finally, save the VOS database
    pg_dump --clean --if-exists -f ${fpath} -d ${PGDATABASE}
    chmod 440 ${fpath}

elif [ "$COMMAND" = "restore" ]; then
    dfile=`basename $DUMPFILE`
    dpath="${BACKUP_DIR}/${dfile}"
    if [ $DEBUG -eq 1 ]; then
        echo "Restore action variables:"
        echo "  DUMPFILE = $DUMPFILE"
        echo "  dfile    = $dfile"
        echo "  dpath    = $dpath"
        echo "------------------------------------------------------------"
    fi

    if [ ! -f "$dpath" -o ! -r "$dpath" ]; then
        echo "ERROR: The given restore file '$dfile' must exist and be readable within"
        echo "       a directory mounted by the container at ${BACKUP_DIR}"
        Usage
        exit 21
    fi

    if [ $VERBOSE -eq 1 ]; then
        echo "Restoring the VOS database from container-mounted path ${dpath} ..."
    fi

    # finally, restore the VOS database
    psql ${PGDATABASE} < ${dpath}
fi

exit 0
