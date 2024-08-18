# EC2Spec

`ec2spec.sh` is a Bash script to fetch and display Amazon EC2 instance types based on specified vCPU and RAM requirements. It can also fetch and display spot prices for the matching instance types.

## Usage

```bash
./ec2spec.sh [-r REGION] [-v VCPU] [-m RAM] [-s] 
```
## Options

* `-r`, `--region`: AWS region (default: region configured in AWS CLI)
* `-v`, `--vcpu`: Number of vCPUs required
* `-m`, `--ram`: Amount of RAM required (in GB)
* `-s`, `--spot`: Fetch and display spot prices for the matching instance types

## Examples

* **Fetch Instance Types**

   Fetch instance types with 4 vCPUs and 16 GB RAM in the `us-west-2` region:

   ```bash
   ./ec2spec.sh -v 4 -m 16 -r us-west-2
   ```

* **Fetch Spot Prices**

   Fetch spot prices for instance types with 4 vCPUs and 16 GB RAM in the `us-west-2` region:

   ```bash
   ./ec2spec.sh -v 4 -m 16 -r us-west-2 -s