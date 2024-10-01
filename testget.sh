while getopts ":a:bc" opt; do
  case $opt in
    a)
      echo "Option -a was triggered, Argument: $OPTARG"
      ;;
    b)
      echo "Option -b was triggered"
      ;;
    c)
      echo "Option -c was triggered"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
