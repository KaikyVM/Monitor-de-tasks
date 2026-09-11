import boto3
import time
import base64
import json

REGION = "us-east-1"
ROLE_NAME = "role-tcc-ec2-ssm-test"
INSTANCE_PROFILE_NAME = "profile-tcc-ec2-ssm-test"
SG_NAME = "tcc-ec2-ssm-test-sg"
AMI_ID = "ami-0c02fb55956c7d316" # Amazon Linux 2 in us-east-1 (or we can query it)

ec2 = boto3.client("ec2", region_name=REGION)
iam = boto3.client("iam", region_name=REGION)
ssm = boto3.client("ssm", region_name=REGION)

def setup_iam():
    print("Setting up IAM role and instance profile for SSM...")
    try:
        iam.get_role(RoleName=ROLE_NAME)
    except iam.exceptions.NoSuchEntityException:
        assume_role_policy = {
            "Version": "2012-10-17",
            "Statement": [{"Effect": "Allow", "Principal": {"Service": "ec2.amazonaws.com"}, "Action": "sts:AssumeRole"}]
        }
        iam.create_role(RoleName=ROLE_NAME, AssumeRolePolicyDocument=json.dumps(assume_role_policy))
        iam.attach_role_policy(RoleName=ROLE_NAME, PolicyArn="arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore")
        iam.attach_role_policy(RoleName=ROLE_NAME, PolicyArn="arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess")
        time.sleep(10)
        
    try:
        iam.get_instance_profile(InstanceProfileName=INSTANCE_PROFILE_NAME)
    except iam.exceptions.NoSuchEntityException:
        iam.create_instance_profile(InstanceProfileName=INSTANCE_PROFILE_NAME)
        iam.add_role_to_instance_profile(InstanceProfileName=INSTANCE_PROFILE_NAME, RoleName=ROLE_NAME)
        time.sleep(15) # Wait for propagation

def setup_sg():
    print("Setting up Security Group...")
    try:
        response = ec2.describe_security_groups(GroupNames=[SG_NAME])
        return response['SecurityGroups'][0]['GroupId']
    except ec2.exceptions.ClientError:
        response = ec2.create_security_group(
            GroupName=SG_NAME,
            Description="SG for TCC EC2 SSM Test - No inbound rules needed"
        )
        return response['GroupId']

def get_latest_amz2_ami():
    response = ec2.describe_images(
        Owners=['amazon'],
        Filters=[
            {'Name': 'name', 'Values': ['amzn2-ami-hvm-*-x86_64-gp2']},
            {'Name': 'state', 'Values': ['available']}
        ],
    )
    # Sort by CreationDate
    images = sorted(response['Images'], key=lambda k: k['CreationDate'], reverse=True)
    return images[0]['ImageId']

def launch_instance(sg_id, ami_id):
    print(f"Launching EC2 instance (t3.micro) using AMI {ami_id}...")
    response = ec2.run_instances(
        ImageId=ami_id,
        InstanceType="t3.micro",
        MaxCount=1,
        MinCount=1,
        SecurityGroupIds=[sg_id],
        IamInstanceProfile={'Name': INSTANCE_PROFILE_NAME},
        TagSpecifications=[{
            'ResourceType': 'instance',
            'Tags': [{'Key': 'Name', 'Value': 'tcc-ec2-benchmark'}]
        }],
        # Using a public IP just in case, but default VPC does this
    )
    instance_id = response['Instances'][0]['InstanceId']
    
    print(f"Waiting for instance {instance_id} to be running...")
    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=[instance_id])
    print("Instance is running. Waiting for SSM agent to come online (~2 mins)...")
    
    # Wait until SSM recognizes the instance
    ssm_online = False
    for _ in range(30):
        time.sleep(10)
        res = ssm.describe_instance_information(
            Filters=[{'Key': 'InstanceIds', 'Values': [instance_id]}]
        )
        if res['InstanceInformationList'] and res['InstanceInformationList'][0]['PingStatus'] == 'Online':
            ssm_online = True
            break
    
    if not ssm_online:
        raise Exception("SSM Agent did not come online.")
        
    return instance_id

def run_benchmark_via_ssm(instance_id):
    print("Deploying and running benchmark script via SSM...")
    with open("ec2_benchmark.py", "r", encoding="utf-8") as f:
        script_content = f.read()

    b64_script = base64.b64encode(script_content.encode('utf-8')).decode('utf-8')

    commands = [
        # -q suprime o verbose do yum (evita consumir os 24KB do buffer do SSM antes do benchmark)
        "sudo yum groupinstall -y -q 'Development Tools' 2>/dev/null",
        "sudo yum install -y -q openssl11 openssl11-devel openssl11-libs bzip2-devel libffi-devel zlib-devel wget 2>/dev/null",
        # --- Python 3.12.9 ---
        "cd /tmp && wget -q https://www.python.org/ftp/python/3.12.9/Python-3.12.9.tgz",
        "cd /tmp && tar xzf Python-3.12.9.tgz",
        "cd /tmp/Python-3.12.9 && CFLAGS='-I/usr/include/openssl11' LDFLAGS='-L/usr/lib64/openssl11 -Wl,-rpath=/usr/lib64/openssl11' ./configure --quiet >/dev/null 2>&1",
        "cd /tmp/Python-3.12.9 && make -j $(nproc) >/dev/null 2>&1",
        "cd /tmp/Python-3.12.9 && sudo make altinstall >/dev/null 2>&1",
        # --- Verificações visíveis no stdout ---
        "python3.12 --version",
        "python3.12 -c \"import ssl; print('OpenSSL:', ssl.OPENSSL_VERSION)\"",
        # --- boto3/botocore exatos ---
        "python3.12 -m pip install -q boto3==1.42.97 botocore==1.42.97",
        "python3.12 -c \"import boto3, botocore; print('boto3:', boto3.__version__, '| botocore:', botocore.__version__)\"",
        # --- Benchmark: salvar em arquivo E imprimir no stdout ---
        f"echo '{b64_script}' | base64 -d > /tmp/ec2_benchmark.py",
        "python3.12 /tmp/ec2_benchmark.py | tee /tmp/benchmark_results.txt",
        # --- Safety net: imprimir o arquivo caso o tee falhe ---
        "echo '--- BENCHMARK FILE ---' && cat /tmp/benchmark_results.txt"
    ]

    response = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': commands,
            'executionTimeout': ['3600']   # 60 min de timeout no SSM (compilação + benchmark)
        }
    )

    command_id = response['Command']['CommandId']
    print(f"Command sent (ID: {command_id}). Aguardando (compilacao Python 3.12 leva ~15-20 min)...")

    # Loop estendido: 100 × 30s = 50 min máximo
    for poll in range(100):
        time.sleep(30)
        res = ssm.list_command_invocations(
            CommandId=command_id,
            InstanceId=instance_id,
            Details=True
        )
        if res['CommandInvocations']:
            status = res['CommandInvocations'][0]['Status']
            elapsed = (poll + 1) * 30
            print(f"  [{elapsed}s] Status: {status}")
            if status in ['Success', 'Failed', 'TimedOut', 'Cancelled']:
                print(f"Execution finished with status: {status}")
                plugin_output = res['CommandInvocations'][0]['CommandPlugins'][0]
                print("\n=== OUTPUT ===")
                print(plugin_output.get('Output', ''))
                print("==============")
                # Buscar output completo via get_command_invocation (sem truncamento do SSM)
                full = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
                print("\n=== STDOUT COMPLETO ===")
                print(full['StandardOutputContent'])
                print("=== STDERR ===")
                print(full['StandardErrorContent'])
                break

def cleanup(instance_id, sg_id):
    print("Terminating EC2 instance...")
    ec2.terminate_instances(InstanceIds=[instance_id])
    waiter = ec2.get_waiter('instance_terminated')
    waiter.wait(InstanceIds=[instance_id])
    print("Instance terminated.")

if __name__ == "__main__":
    setup_iam()
    sg_id = setup_sg()
    ami_id = get_latest_amz2_ami()
    instance_id = launch_instance(sg_id, ami_id)
    try:
        run_benchmark_via_ssm(instance_id)
    finally:
        cleanup(instance_id, sg_id)
    print("EC2 test complete.")
