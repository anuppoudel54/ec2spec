#!/bin/bash
usage() {
  echo "Usage: ec2spec.sh -r <region> -v <vCPU> -m <RAM> [-s|--spot]"
  exit 1
}

REGION=$(aws configure get region)
SPOT=false
ONDEMAND=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -r|--region) REGION="$2"; shift ;;
    -v|--vcpu) VCPU="$2"; shift ;;
    -m|--ram) RAM="$2"; shift ;;
    -s|--spot) SPOT=true ;;
    -o|--ondemand) ONDEMAND=true ;;
    *) usage ;;
  esac
  shift
done

if [ -z "$VCPU" ] || [ -z "$RAM" ]; then
  echo "vCPU and RAM are required."
  usage
fi

INSTANCE_DATA_FILE="/tmp/ec2_instance_types_${REGION}_${VCPU}vcpu_${RAM}gb.json"
fetch_instance_types() {
  
  RAM_MIB=$(echo "$RAM * 1024" | bc)
  
  instance_types=$(aws ec2 describe-instance-types --region "$REGION" \
    --filters "Name=vcpu-info.default-vcpus,Values=$VCPU" \
              "Name=memory-info.size-in-mib,Values=$RAM_MIB" \
    --query 'InstanceTypes[*].InstanceType' --output json)
  
  json_data="{\"InstanceTypes\": $instance_types}"
  echo $json_data > $INSTANCE_DATA_FILE
  
  echo "Instance types matching $VCPU vCPUs and $RAM GB RAM in $REGION:"
  echo $json_data | jq -r '.InstanceTypes[]'
}




get_spot_price() {
  SPOT_PRICE_FILE="/tmp/spot_prices_${REGION}_${VCPU}vcpu_${RAM}gb.json"
  
  
  if [ ! -f "$INSTANCE_DATA_FILE" ]; then
    echo "Error: Instance data file $INSTANCE_DATA_FILE does not exist."
    echo "Fetching instance types..."
    fetch_instance_types
  fi
  
  if [ ! -r "$INSTANCE_DATA_FILE" ]; then
    echo "Error: Instance data file $INSTANCE_DATA_FILE is not readable."
    exit 1
  fi
  
  instance_types=$(jq -r '.InstanceTypes[]' "$INSTANCE_DATA_FILE")
  spot_prices=()
  
  echo -n "Checking spot prices"
  for instance_type in $instance_types; do
    price=$(aws ec2 describe-spot-price-history --region "$REGION" \
      --instance-types "$instance_type" --product-descriptions "Linux/UNIX" \
      --query 'SpotPriceHistory[0].SpotPrice' --output text 2>/dev/null)
    spot_prices+=("{\"InstanceType\": \"$instance_type\", \"SpotPrice\": $price}")
    echo -n "*"
  done
  echo ""
  
  # Create JSON structure from spot prices and write to file
  json_data="{\"SpotPrices\": [$(IFS=,; echo "${spot_prices[*]}")]}"
  echo $json_data > $SPOT_PRICE_FILE
  
  # Sort and display spot prices
#   echo "Spot prices in ascending order:"
#   jq '.SpotPrices | sort_by(.SpotPrice)' $SPOT_PRICE_FILE
  
# Sort and display spot prices
echo "Spot prices in ascending order:"
sorted_spot_prices=$(jq -r '.SpotPrices | sort_by(.SpotPrice)[] | [.InstanceType, .SpotPrice] | @tsv' $SPOT_PRICE_FILE)

# Print table header
printf "%-20s %-10s\n" "InstanceType" "SpotPrice"
printf "%-20s %-10s\n" "------------" "---------"

# Print sorted spot prices
echo "$sorted_spot_prices" | while IFS=$'\t' read -r instance_type spot_price; do
  printf "%-20s %-10s\n" "$instance_type" "$spot_price"
done

  echo "Spot prices saved to $SPOT_PRICE_FILE"
}

# Call the appropriate function based on the SPOT argument
if [ "$SPOT" = true ]; then
  get_spot_price
else
  fetch_instance_types
fi

