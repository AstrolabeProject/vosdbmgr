#!/bin/bash --norc
#
#  Written by: Tom Hicks. 12/9/2019.
#  Last Modified: Initial creation.
#
#  Backup and/or restore the PostgreSQL VosDB database.
#
#  Examples:
#

# Use or initialize standard PostgreSQL environment variables:
export PGDATABASE=${PGDATABASE:-vos}
export PGHOST=${PGHOST:-pgdb}
export PGPASSFILE=${PGPASSFILE:-.pgpass}
export PGPORT=${PGPORT:-5432}
export PGUSER=${PGUSER:-astrolabe}


# Internal variables or script argument variables:
BACKUP_DIR=/backups
COMMAND=
DEBUG=0
DUMPFILE=vos
VERBOSE=0


Usage () {
    echo "Usage: $0 [-h] -c command -f dumpfile [-u username] [-v | --debug]"
    echo "where:"
    echo "    -h, --help          - print this help message and exit"
    echo "    -c, --cmd command   - what to do: 'save' or 'restore' (required)"
    echo "    -f, --file dumpfile - filename of the dump file to be created or restored (required)"
    echo "    -u, --user name     - the username of a DB administrator (default: ${PGUSER})"
    echo "    -v, --verbose       - provide more information during run (default: ${VERBOSE})"
    echo "    --debug             - show additional debugging information"
    echo ""
}

# Test for too few arguments or the help argument
if [ $# -lt 2 -o "$1" = "-h" -o "$1" = "--help" ]; then
  Usage
  exit 1
fi

# Parse the script arguments:
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
        "-u"|"--user") shift
                       export PGUSER=${1:-astrolabe}
                       ;;
        "-v"|"--verbose") VERBOSE=1
                          ;;
        "--debug") DEBUG=1
                   VERBOSE=1
                   ;;
        *) echo "ERROR: Unknown optional argument: $1"
           Usage
           exit 2
           ;;
    esac
    shift
done


# print variables for debugging:
#
if [ $DEBUG -eq 1 ]; then
    echo "------------------------------------------------------------"
    echo "PostgreSQL Environment Variables:"
    echo "  PGDATABASE  = $PGDATABASE"
    echo "  PGHOST      = $PGHOST"
    echo "  PGPASSFILE  = $PGPASSFILE"
    echo "  PGPORT      = $PGPORT"
    echo "  PGUSER      = $PGUSER"
    echo ""
    echo "Command Line Arguments:"
    echo "  COMMAND     = $COMMAND"
    echo "  BACKUP_DIR  = $BACKUP_DIR"
    echo "  DUMPFILE    = $DUMPFILE"
    echo "  VERBOSE     = $VERBOSE"
    echo "  DEBUG       = $DEBUG"
    echo "------------------------------------------------------------"
    echo ""
fi


# sanity tests for the script arguments:
#

# test for the command argument
c1=`echo $COMMAND | cut -c1`
if [ -z "$COMMAND" -o -z "$c1" -o "$c1" = "-" ]; then
    echo "ERROR: The specified command ($COMMAND) may not be empty or begin with '-'."
    echo "       Did you forgot to specify a command after the -c or --cmd flag?"
    Usage
    exit 10
fi

if [ "$COMMAND" != "save" -a "$COMMAND" != "restore" ]; then
    echo "ERROR: Command must be one of 'save' or 'restore', not: '$COMMAND'"
    Usage
    exit 11
fi


# test for the dump filename argument
f1=`echo $DUMPFILE | cut -c1`
if [ -z "$DUMPFILE" -o -z "$f1" -o "$f1" = "-" ]; then
    echo "ERROR: The specified dump filename ($DUMPFILE) may not be empty or begin with '-'."
    echo "       Did you forgot to specify the dump filename after the -f or --file flag?"
    Usage
    exit 20
fi

u1=`echo $PGUSER | cut -c1`
if [ -z "$PGUSER" -o -z "$u1" -o "$u1" = "-" ]; then
    echo "ERROR: The specified DB admin username ($PGUSER) may not be empty or begin with '-'."
    echo "       Did you forgot to specify the DB admin username after the -u or --user flag?"
    Usage
    exit 12
fi

# If command is restore, check that specified dump file exists in the backup directory
if [ "$COMMAND" = "restore" ]; then
    dpath="${BACKUP_DIR}/${DUMPFILE}"
    if [ ! -f "$dpath" -o ! -r "$dpath" ]; then
        echo "ERROR: The specified dump file ($DUMPFILE) must exist in the ${BACKUP_DIR} and be readable."
        Usage
        exit 20
    fi
fi


# Do the actual backup or restore work
if [ "$COMMAND" = "save" ]; then
    ftime=`date +%y-%m-%d_%H.%M`
    fname="${DUMPFILE}_${ftime}.sql"
    fpath="${BACKUP_DIR}/${fname}"
    # uses environment variables for PGHOST, PGPORT, PGUSER
    pg_dump --clean --if-exists -f ${fpath} -d ${PGDATABASE}
    chmod 440 ${fpath}

elif [ "$COMMAND" = "restore" ]; then
    dpath="${BACKUP_DIR}/${DUMPFILE}"
    echo "Copying ${dpath} to / ..."
    cp -p ${dpath} /
    echo "Restoring database from ${DUMPFILE} ..."
    psql ${PGDATABASE} < /${DUMPFILE}

fi


exit 0
